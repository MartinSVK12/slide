package sunsetsatellite.slide

import godot.annotation.Register
import godot.annotation.Script
import godot.core.Color
import godot.core.Dictionary
import godot.core.dictionaryOf
import sunsetsatellite.sunlite.lang.Expr
import sunsetsatellite.sunlite.lang.FunctionType
import sunsetsatellite.sunlite.lang.Stmt
import sunsetsatellite.sunlite.lang.Token
import sunsetsatellite.sunlite.lang.TokenType
import sunsetsatellite.sunlite.lang.TokenType.TokenGroup.*
import sunsetsatellite.sunlite.lang.Type

@Script
class SunliteDynamicCodeHighlighter: SunliteCodeHighlighter() {

	@Register
	override fun _getLineSyntaxHighlighting(line: Int): Dictionary<Any?, Any?> {
		val dict = dictionaryOf<Any?,Any?>()
		getTextEdit()?.getLine(line)?.startsWith("//")?.let {
			dict[0] = dictionaryOf<Any?, Any?>("color" to commentColor)
		}
		(getTextEdit()?.getNode("/root/IDE/CodeAnalysis") as? CodeAnalysis)?.lastValidAnalysis?.let { last ->
			last.first.filter { it.line-1 == line && it.hasValidPosition()}.forEach {
				when(it.type) {
					TokenType.IDENTIFIER -> {
						if(it.literal is String){
							"::".toRegex().findAll(it.literal).forEach { match ->
								addSection(it.pos.start+match.range.first,it.pos.start+match.range.last, Color("999999"), dict)
							}
						}
						addSection(line,it, Color("dfdfdf"), dict)
					}
					TokenType.STRING -> addSection(line,it, stringColor, dict)
					else -> {
						when {
							it.type.contains(CONTROL) -> {
								addSection(line,it, controlKeywordColor, dict)
							}
							it.type.contains(KEYWORDS) -> {
								addSection(line,it, keywordColor, dict)
							}
							it.type.contains(MODIFIERS) -> {
								addSection(line,it, keywordColor, dict)
							}
							it.type.contains(TYPES) -> {
								addSection(line,it, typeKeywordColor, dict)
							}
							it.type.contains(NUMBERS) -> {
								addSection(line,it, numberColor, dict)
							}
							else -> {}
						}
					}
				}
			}
			last.second.forEach { stmt ->
				stmt.accept(ContextAwareHighlighter(line, dict))
			}
		}
		return dict
	}

	fun addSection(start: Int, end: Int, color: Color, dict: Dictionary<Any?, Any?>) {
		dict[start] = dictionaryOf<Any?, Any?>("color" to color)
		dict[end] = dictionaryOf<Any?, Any?>("color" to Color("999999"))
	}

	fun addSection(line: Int, token: Token, color: Color, dict: Dictionary<Any?, Any?>) {
		if(!token.hasValidPosition()) return
		if(token.line-1 != line) return
		dict[token.pos.start] = dictionaryOf<Any?, Any?>("color" to color)
		dict[token.pos.end] = dictionaryOf<Any?, Any?>("color" to Color("999999"))
	}

	inner class ContextAwareHighlighter(val line: Int, val dict: Dictionary<Any?, Any?>) : Stmt.Visitor<Unit>, Expr.Visitor<Unit> {

		val usedIdentifiers = mutableSetOf<String>()

		override fun visitExprStmt(stmt: Stmt.Expression) {
			stmt.expr.accept(this)
		}

		override fun visitPrintStmt(stmt: Stmt.Print) {
			// nothing to collect
		}

		override fun visitVarStmt(stmt: Stmt.Var) {
			markTypeParameters(stmt.type)
			stmt.initializer?.accept(this)
		}

		override fun visitBlockStmt(stmt: Stmt.Block) {
			stmt.statements.forEach { it.accept(this) }
		}

		override fun visitIfStmt(stmt: Stmt.If) {
			stmt.condition.accept(this)
			stmt.thenBranch.accept(this)
			stmt.elseBranch?.accept(this)
		}

		override fun visitWhileStmt(stmt: Stmt.While) {
			stmt.condition.accept(this)
			stmt.body.accept(this)
		}

		override fun visitBreakStmt(stmt: Stmt.Break) {
			// nothing to collect
		}

		override fun visitContinueStmt(stmt: Stmt.Continue) {
			// nothing to collect
		}

		override fun visitFunctionStmt(stmt: Stmt.Function) {
			if(stmt.type != FunctionType.LAMBDA) {
				addSection(line,stmt.name, functionColor, dict)
			}
			stmt.typeParameters.forEach { addSection(line, it.token, typeParameterColor, dict) }
			markTypeParameters(stmt.returnType)
			stmt.params.forEach { markTypeParameters(it.type) }
			stmt.body.forEach { it.accept(this) }
		}

		fun markTypeParameters(type: Type){
			if(type is Type.Parameter){
				if(type.token != null){
					addSection(line, type.token!!, typeParameterColor, dict)
				}
			} else if(type is Type.Reference){
				type.params.forEach { markTypeParameters(it.type) }
				markTypeParameters(type.returnType)
				type.typeParams.forEach { markTypeParameters(it.type) }
			} else if(type is Type.Union){
				type.types.forEach { markTypeParameters(it) }
			}
		}

		override fun visitReturnStmt(stmt: Stmt.Return) {
			stmt.value?.accept(this)
		}

		override fun visitClassStmt(stmt: Stmt.Class) {
			stmt.superclass?.let {
				it.accept(this)
			}
			//addSection(line,stmt.name, memberVariableColor, dict)
			stmt.typeParameters.forEach { addSection(line, it.token, typeParameterColor, dict) }
			stmt.fieldDefaults.forEach {
				it.accept(this)
				usedIdentifiers.add(it.name.lexeme)
				addSection(line,it.name, memberVariableColor, dict)
			}
			stmt.methods.forEach { it.accept(this) }
			usedIdentifiers.clear()
		}

		override fun visitInterfaceStmt(stmt: Stmt.Interface) {
			stmt.typeParameters.forEach { addSection(line, it.token, typeParameterColor, dict) }
			stmt.methods.forEach { it.accept(this) }
		}

		override fun visitIncludeStmt(stmt: Stmt.Include) {
			// nothing to collect
		}

		override fun visitImportStmt(stmt: Stmt.Import) {
			// nothing to collect
		}

		override fun visitModuleStmt(stmt: Stmt.Module) {
			stmt.stmts.forEach { it.accept(this) }
		}

		override fun visitTryCatchStmt(stmt: Stmt.TryCatch) {
			stmt.tryBody.accept(this)
			stmt.catchBody.accept(this)
		}

		override fun visitThrowStmt(stmt: Stmt.Throw) {
			stmt.expr.accept(this)
		}

		override fun visitAnnotationStmt(stmt: Stmt.Annotation) {

		}

		override fun visitSuperInitStmt(stmt: Stmt.SuperInit) {
			stmt.expr.accept(this)
		}

		override fun visitBinaryExpr(expr: Expr.Binary) {
			expr.left.accept(this)
			expr.right.accept(this)
		}

		override fun visitGroupingExpr(expr: Expr.Grouping) {
			expr.expression.accept(this)
		}

		override fun visitUnaryExpr(expr: Expr.Unary) {
			expr.right.accept(this)
		}

		override fun visitLiteralExpr(expr: Expr.Literal) {

		}

		override fun visitVariableExpr(expr: Expr.Variable) {
			if (usedIdentifiers.contains(expr.name.lexeme)) addSection(line, expr.name, memberVariableColor, dict)
		}

		override fun visitAssignExpr(expr: Expr.Assign) {
			expr.value.accept(this)
		}

		override fun visitLogicalExpr(expr: Expr.Logical) {
			expr.left.accept(this)
			expr.right.accept(this)
		}

		override fun visitCallExpr(expr: Expr.Call) {
			expr.callee.accept(this)
			expr.arguments.forEach { it.accept(this) }
			expr.typeArgs.forEach { markTypeParameters(it.type) }
			if(expr.callee is Expr.Get){
				addSection(line,expr.callee.name, functionColor, dict)
			}
			if(expr.callee is Expr.Variable){
				addSection(line,expr.callee.name, functionColor, dict)
			}
		}

		override fun visitLambdaExpr(expr: Expr.Lambda) {
			expr.function.accept(this)
		}

		override fun visitGetExpr(expr: Expr.Get) {
			if (usedIdentifiers.contains(expr.name.lexeme)) addSection(line, expr.name, memberVariableColor, dict)
			expr.obj.accept(this)
		}

		override fun visitArrayGetExpr(expr: Expr.ArrayGet) {
			if(expr.obj is Expr.NamedExpr){
				if (usedIdentifiers.contains(expr.obj.getNameToken().lexeme)) addSection(line, expr.obj.getNameToken(), memberVariableColor, dict)
			}
			expr.obj.accept(this)
			expr.what.accept(this)
		}

		override fun visitArraySetExpr(expr: Expr.ArraySet) {
			if(expr.obj is Expr.NamedExpr){
				if (usedIdentifiers.contains(expr.obj.getNameToken().lexeme)) addSection(line, expr.obj.getNameToken(), memberVariableColor, dict)
			}
			expr.obj.accept(this)
			expr.what.accept(this)
			expr.value.accept(this)
		}

		override fun visitSetExpr(expr: Expr.Set) {
			if (usedIdentifiers.contains(expr.name.lexeme)) addSection(line, expr.name, memberVariableColor, dict)
			expr.obj.accept(this)
			expr.value.accept(this)
		}

		override fun visitThisExpr(expr: Expr.This) {

		}

		override fun visitSuperExpr(expr: Expr.Super) {

		}

		override fun visitCheckExpr(expr: Expr.Check) {
			expr.left.accept(this)
		}

		override fun visitCastExpr(expr: Expr.Cast) {
			expr.left.accept(this)
		}

		override fun visitArrayExpr(expr: Expr.Array) {
			expr.expr.forEach { it.accept(this) }
		}

		override fun visitIfExpr(expr: Expr.If) {
			expr.condition.accept(this)
			expr.thenBranch.accept(this)
			expr.elseBranch.accept(this)
		}

		override fun visitTupleExpr(expr: Expr.Tuple) {
			expr.expr.forEach { it.accept(this) }
		}

		override fun visitMultiSetExpr(expr: Expr.MultiSet) {
			expr.objs.forEach { it.accept(this) }
			expr.collection.accept(this)
		}

	}
}