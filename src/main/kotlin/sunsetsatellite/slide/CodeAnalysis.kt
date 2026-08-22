package sunsetsatellite.slide

import godot.annotation.Emit
import godot.annotation.Export
import godot.api.Node
import godot.annotation.Script
import godot.annotation.Visible
import godot.api.RichTextLabel
import godot.api.Time
import godot.api.Timer
import godot.core.Dictionary
import godot.core.VariantArray
import godot.core.Vector2i
import godot.core.dictionaryOf
import godot.core.lambdaCallable0
import godot.core.signal2
import godot.core.toVariantArray
import godot.core.variantArrayOf
import sunsetsatellite.sunlite.lang.CompilerDataReceiver
import sunsetsatellite.sunlite.lang.CompilerError
import sunsetsatellite.sunlite.lang.LogEntryReceiver
import sunsetsatellite.sunlite.lang.Stmt
import sunsetsatellite.sunlite.lang.Sunlite
import sunsetsatellite.sunlite.lang.Token
import sunsetsatellite.sunlite.lang.TypeCollector
import java.io.PrintWriter
import java.io.StringWriter
import kotlin.concurrent.thread

@Script
class CodeAnalysis: Node(), CompilerDataReceiver, LogEntryReceiver {
	@Export
	val timer: Timer by lazy { getNode<Timer>("Timer") }

	@Visible
	var lastAnalysisTime: Long = 0

	var inProgress = false
	var lastAnalysis: Pair<List<Token>,List<Stmt>>? = null
	var lastValidAnalysis: Pair<List<Token>,List<Stmt>>? = null
	var lastTypeCollection: TypeCollector? = null

	val errors: MutableList<CompilerError> = mutableListOf()
	val errMsgs: MutableList<String> = mutableListOf()
	var thread: Thread? = null

	@Emit("errors","tokens")
	val signalAnalysisCompleted by signal2<VariantArray<Dictionary<String,Any?>>, VariantArray<Dictionary<String,Any?>>>()

	// Called when the node enters the scene tree for the first time.
    override fun _ready() {
		lastAnalysisTime = Time.getTicksMsec()
        timer.timeout.connect(lambdaCallable0 {
			if(inProgress) return@lambdaCallable0
	        if(!IDE().hasFocusedFile()) return@lambdaCallable0
	        if(IDE().focusedEditor?.ext != "sl") return@lambdaCallable0
	        analyze(IDE().projectPath)
        })
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    override fun _process(delta: Double) {
        
    }

	fun analyze(project: String) {
		inProgress = true
		lastAnalysisTime = Time.getTicksMsec()
		errors.clear()
		errMsgs.clear()
		val path = IDE().focusedEditor?.path ?: ""
		val code = IDE().focusedEditor?.text ?: ""
		thread = thread(start = true, name = "Sunlite Code Analysis") {
			val sl = Sunlite(arrayOf(
				path,
				project
			))
			sl.compilerDataReceivers.add(this)
			sl.logEntryReceivers.add(this)
			val result = sl.parse(code)
			analysisFinished(errors,result.tokens to result.statements)
		}
		thread?.setUncaughtExceptionHandler { t, e ->
			if(e is ThreadDeath) return@setUncaughtExceptionHandler
			val sw = StringWriter()
			e.printStackTrace(PrintWriter(sw))
			val s = sw.toString()
			error(CompilerError(Token.unknown(),s))
			analysisFinished(errors)
		}
	}

	fun analysisFinished(errors: List<CompilerError>, result: Pair<List<Token>,List<Stmt>>? = null){
		inProgress = false
		lastAnalysis = result
		lastAnalysisTime = Time.getTicksMsec()
		if(errors.isEmpty()){
			lastValidAnalysis = result
			lastTypeCollection = Sunlite.instance.collector
		}
		//signalAnalysisCompleted.emit(errors, result?.first ?: listOf())
		val tokens = result?.first?.map { dictionaryOf<String,Any?>(
			"name" to it.type.name,
			"lexeme" to it.lexeme,
			"file" to (it.file ?: ""),
			"line" to it.line,
			"pos" to dictionaryOf<String,Any?>("x" to it.pos.start, "y" to it.pos.end))
		}?.toVariantArray()
		val errors = errors.mapIndexed { index, it -> dictionaryOf<String, Any?>(
			"token" to dictionaryOf<String,Any?>(
				"name" to it.token.type.name,
				"lexeme" to it.token.lexeme,
				"file" to (it.token.file ?: ""),
				"line" to it.token.line,
				"pos" to dictionaryOf<String,Any?>("x" to it.token.pos.start, "y" to it.token.pos.end)),
			"message" to errMsgs[index])
		}.toVariantArray()
		godot.api.Thread.setThreadSafetyChecksEnabled(false)
		signalAnalysisCompleted.emit(errors, tokens ?: variantArrayOf())
		val errLog = getNode<RichTextLabel>("%ErrorLog")
		errLog.text = ""
		errMsgs.forEach {
			errLog.appendText("[color=red]$it[/color]\n")
		}
		godot.api.Thread.setThreadSafetyChecksEnabled(true)
	}

	override fun error(error: CompilerError) {
		errors.add(0,error)
	}

	override fun info(message: String) {

	}

	override fun warn(message: String) {

	}

	override fun err(message: String) {
		errMsgs.add(0, message)
	}
}
