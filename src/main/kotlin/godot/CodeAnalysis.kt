package godot

import godot.annotation.RegisterClass
import godot.annotation.RegisterFunction
import godot.annotation.RegisterSignal
import godot.api.CodeEdit
import godot.api.Node
import godot.api.TabContainer
import godot.core.*
import godot.global.GD
import sunsetsatellite.lang.sunlite.Expr
import sunsetsatellite.lang.sunlite.LogEntryReceiver
import sunsetsatellite.lang.sunlite.PrimitiveType
import sunsetsatellite.lang.sunlite.Sunlite
import sunsetsatellite.lang.sunlite.Stmt
import sunsetsatellite.lang.sunlite.SymbolFinder
import sunsetsatellite.lang.sunlite.Token
import sunsetsatellite.lang.sunlite.Type
import sunsetsatellite.lang.sunlite.TypeCollector
import sunsetsatellite.vm.sunlite.DefaultNatives
import java.io.PrintWriter
import java.io.StringWriter
import java.lang.Thread
import kotlin.concurrent.thread

@RegisterClass
class CodeAnalysis: Node() {

    companion object {
        var inProgress = false
        var lastAnalysis: Pair<List<Token>,List<Stmt>>? = null
	    var lastValidAnalysis: Pair<List<Token>,List<Stmt>>? = null
	    var lastTypeCollection: TypeCollector? = null
    }

    @RegisterSignal("errors","tokens")
    val analysisCompleted by signal2<VariantArray<String>,VariantArray<Dictionary<Any?,Any?>>>()
    
    // Called when the node enters the scene tree for the first time.
    @RegisterFunction
    override fun _ready() {
        
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    @RegisterFunction
    override fun _process(delta: Double) {
        
    }

    fun analysisFinished(errors: List<String>, result: Pair<List<Token>,List<Stmt>>? = null){
        inProgress = false
        lastAnalysis = result
	    if(errors.isEmpty()){
			lastValidAnalysis = result
		    lastTypeCollection = Sunlite.instance.collector
	    }
        val tokens = result?.first?.map { dictionaryOf<Any?,Any?>(
            "name" to it.type.name,
            "type" to it.type.group.name,
            "lexeme" to it.lexeme,
            "file" to (it.file ?: ""),
            "line" to it.line,
            "pos" to Vector2i(it.pos.start,it.pos.end))
        }?.toVariantArray()
        godot.api.Thread.setThreadSafetyChecksEnabled(false)
        analysisCompleted.emit(errors.toVariantArray(), tokens ?: variantArrayOf())
        godot.api.Thread.setThreadSafetyChecksEnabled(true)
    }

    @RegisterFunction
    fun _on_timer_timeout() {
        if(inProgress) return
        val file: String = ((this.getNode("%ScriptTabs".asNodePath()) as TabContainer).getCurrentTabControl()?.get("file".asStringName()) ?: "").toString()
        if(file == "") return
        val scriptWindow = (this.getNode("%ScriptTabs".asNodePath()) as TabContainer).getCurrentTabControl() ?: return
        val code: String = ((scriptWindow as CodeEdit).text)
        val folders: Array<String> = (getTree()?.currentScene?.get("folders".asStringName()) as VariantArray<String>).toTypedArray()
        CodeAnalysisThread(this).analyze(file,folders,code)
    }

    @RegisterFunction
    fun _on_symbol_hovered(symbol: String, line: Int, column: Int): String {
        //GD.print("Hovered $symbol on line $line, column $column")
        //GD.print("Last analysis available: ${lastAnalysis != null}")
	    lastAnalysis?.let {
            val foundElement = SymbolFinder(symbol, line+1, column).find(it.second)
            if(foundElement is Expr){
                return foundElement.getExprType().toString()
            }
        }
        return ""
    }

	@RegisterFunction
	fun _on_member_completion_requested(word: String, line: Int, column: Int, edit: CodeEdit){
		lastValidAnalysis?.let {
			val foundElement = SymbolFinder(null, line+1, column).find(it.second)
			if(foundElement is Expr){
				val type = foundElement.getExprType()
				if(type is Type.Reference){
					val returnType = type.returnType
					if(returnType is Type.Reference && (returnType.type == PrimitiveType.OBJECT || returnType.type == PrimitiveType.CLASS)){
						//GD.print(returnType.toString())
						lastTypeCollection?.let {
							val prototype = lastTypeCollection!!.typeHierarchy[type.returnType.getName()]
							prototype?.let {
								it.scope.contents.forEach { (token, member) ->
									if(token.lexeme.startsWith(word)){
										if(member is TypeCollector.FunctionPrototype) {
											edit.addCodeCompletionOption(
												type = CodeEdit.CodeCompletionKind.KIND_FUNCTION,
												displayText = member.modifier.toString() + member.toString(),
												insertText = token.lexeme.replace(word,""),
												location = 0
											)
										} else if(member is TypeCollector.VariablePrototype){
											edit.addCodeCompletionOption(
												type = CodeEdit.CodeCompletionKind.KIND_VARIABLE,
												displayText = token.lexeme+member.toString(),
												insertText = token.lexeme.replace(word,""),
												location = 0
											)
										}
									} else if(word.isBlank()){
										if(member is TypeCollector.FunctionPrototype) {
											edit.addCodeCompletionOption(
												type = CodeEdit.CodeCompletionKind.KIND_FUNCTION,
												displayText = member.modifier.toString() + member.toString(),
												insertText = token.lexeme,
												location = 0
											)
										} else if(member is TypeCollector.VariablePrototype){
											edit.addCodeCompletionOption(
												type = CodeEdit.CodeCompletionKind.KIND_VARIABLE,
												displayText = token.lexeme+member.toString(),
												insertText = token.lexeme,
												location = 0
											)
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	@RegisterFunction
	fun _on_code_completion_requested(word: String, line: Int, column: Int, edit: CodeEdit){
		DefaultNatives.DefaultNativesContainer.getNatives().forEach { (name, _) ->
			if(name.startsWith(word)){
				var signature = name
				val type = lastTypeCollection?.findType(Token.identifier(name, line))
				type?.let { signature = (it as TypeCollector.FunctionPrototype).modifier.toString() + it.toString() }
				edit.addCodeCompletionOption(
					type = CodeEdit.CodeCompletionKind.KIND_FUNCTION,
					displayText = signature.replace("#","."),
					insertText = name.replace(word,"").replace("#","."),
					location = 512
				)
			}
		}
		lastTypeCollection?.let {
			it.typeScopes.firstOrNull()?.let {
				it.inner.forEach { scope ->
					scope.contents.forEach { (token, prototype) ->
						if(token.lexeme.startsWith(word)){
							if(prototype is TypeCollector.FunctionPrototype) {
								edit.addCodeCompletionOption(
									type = CodeEdit.CodeCompletionKind.KIND_FUNCTION,
									displayText = prototype.modifier.toString()+prototype.toString(),
									insertText = token.lexeme.replace(word,""),
									location = 0
								)
							} else if(prototype is TypeCollector.VariablePrototype){
								edit.addCodeCompletionOption(
									type = CodeEdit.CodeCompletionKind.KIND_VARIABLE,
									displayText = token.lexeme+prototype.toString(),
									insertText = token.lexeme.replace(word,""),
									location = 0
								)
							}
						}
					}
				}
			}
		}
	}

    class CodeAnalysisThread(val analysis: CodeAnalysis) : LogEntryReceiver {

        private val errors: MutableList<String> = ArrayList()
        private var thread: Thread? = null

        override fun info(message: String) {

        }

        override fun warn(message: String) {

        }

        override fun err(message: String) {
            errors.add(0, message)
        }

        fun analyze(file: String, loadPath: Array<String> = arrayOf(), code: String? = null) {
            inProgress = true
            thread = thread(
                start = true,
                name = "Sunlite Code Analysis",
            ) {
                val sunlite = Sunlite(arrayOf(file,loadPath.joinToString(";")))
                sunlite.logEntryReceivers.add(this)
                //GdLoxGlobals.registerGlobals(sunlite)
                val result = sunlite.parse(code)
                if(result == null){
                    analysis.analysisFinished(errors)
                    return@thread
                } else {
                    analysis.analysisFinished(errors,result.tokens to result.statements)
                }
            }
            thread!!.setUncaughtExceptionHandler { t, e ->
                if (e is ThreadDeath) return@setUncaughtExceptionHandler
                val sw = StringWriter()
                e.printStackTrace(PrintWriter(sw))
                val s = sw.toString()
                err(s)
                analysis.analysisFinished(errors)
            }
        }

    }
}
