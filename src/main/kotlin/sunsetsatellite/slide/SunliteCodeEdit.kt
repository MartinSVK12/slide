package sunsetsatellite.slide

import godot.annotation.Export
import godot.annotation.Register
import godot.api.CodeEdit
import godot.annotation.Script
import godot.api.ColorRect
import godot.api.InputEvent
import godot.api.Label
import godot.api.Time
import godot.core.Color
import godot.core.Dictionary
import godot.core.VariantArray
import godot.core.Vector2
import godot.core.lambdaCallable0
import godot.core.lambdaCallable2
import godot.core.lambdaCallable3
import godot.global.GD
import sunsetsatellite.sunlite.lang.Expr
import sunsetsatellite.sunlite.lang.Scanner
import sunsetsatellite.sunlite.lang.SymbolFinder
import sunsetsatellite.sunlite.lang.Token
import java.io.File
import java.io.IOException
import java.nio.file.Files
import kotlin.io.path.Path
import kotlin.io.path.extension

@Script
class SunliteCodeEdit: CodeEdit() {

	@Export @godot.annotation.File(global = true)
	var path: String = ""
	var ext: String = ""

	val errorLine by lazy { getNode<ColorRect>("%ErrorLine") }
	val firstError by lazy { getNode<Label>("%FirstError") }
	val errorCount by lazy { getNode<Label>("%ErrorCount") }
	val symbolPopup by lazy { getNode<Label>("%SymbolPopup") }

	val analysisComplete = lambdaCallable2<Unit, VariantArray<Dictionary<String, Any?>>, VariantArray<Dictionary<String, Any?>>> { errors, tokens ->
		showErrors(errors)
	}

	// Called when the node enters the scene tree for the first time.
	override fun _ready() {
		ext = Path(path).extension
		if(ext == "sl"){
			syntaxHighlighter = SunliteCodeHighlighter()
		}
		try {
			text = Files.readString(Path(path))
		} catch (e: IOException) {
			GD.printErr("Error reading file: $e")
		}
		focusEntered.connect(lambdaCallable0 {
			IDE().focusedFile = path
			IDE().focusedEditor = this
			IDE().analysis().lastAnalysisTime = Time.getTicksMsec()
		})
		symbolHovered.connect(lambdaCallable3 { symbol, line, column ->
			onSymbolHovered(symbol, line.toInt(), column.toInt())
		})
		caretChanged.connect(lambdaCallable0 {
			symbolPopup.hide()
			symbolPopup.text = ""
			symbolPopup.setSize(Vector2.ONE)
		})

		IDE().analysis().signalAnalysisCompleted.connect(analysisComplete, ConnectFlags.REFERENCE_COUNTED)
	}

	@Register
	fun onSymbolHovered(symbol: String, line: Int, column: Int) {
		if(getLine(line).startsWith("//")) return
		if(!isValidSymbol(symbol)) return
		val type = getSymbolType(symbol, line, column)
		symbolPopup.text = type
		symbolPopup.setSize(Vector2.ONE)
		symbolPopup.show()
		symbolPopup.setGlobalPosition(getGlobalMousePosition())
	}

	@Register
	fun getSymbolType(symbol: String, line: Int, column: Int): String {
		IDE().analysis().lastValidAnalysis?.let { it ->
			val foundElement = SymbolFinder(
				symbol,
				line + 1,
				column
			).find(it.second)
			if(foundElement is Expr) {
				val expr = foundElement as Expr
				return expr.getExprType().toString()
			}
		}
		return ""
	}

	@Register
	fun showErrors(errors: VariantArray<Dictionary<String, Any?>>) {
		if (errors.isEmpty()) {
			for (i in 0 until getLineCount()) {
				if(getLineBackgroundColor(i).r == 0.75) setLineBackgroundColor(i, Color(0,0,0,0))
			}
			errorLine.hide()
		} else {
			val map = (errors.first()["token"] as Dictionary<String, Any?>).toMap()
			val token = Token(map)
			errorLine.show()
			firstError.text = errors.first()["message"].toString()
			errorCount.text = "[${errors.size} errors]"
			if(token.line >= 0 && token.line < getLineCount()) setLineBackgroundColor(token.line-1, Color(0.75,0,0,0.25))
		}
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	override fun _process(delta: Double) {
		val time = Time.getTicksMsec()
		if (IDE().analysis().lastAnalysisTime+10000 < time && IDE().hasFocusedFile()) {
			errorLine.show()
			firstError.text = "Code analysis unresponsive."
			errorCount.text = "[1 errors]"
		}
	}

	override fun _unhandledKeyInput(event: InputEvent) {
		if (event.isActionPressed("save")) {
			File(path).writeText(text)
		}
	}

	override fun _exitTree() {
		IDE().analysis().signalAnalysisCompleted.disconnect(analysisComplete)
	}

	@Register
	fun isValidSymbol(symbol: String): Boolean {
		return !Scanner.keywords.contains(symbol)
	}
}
