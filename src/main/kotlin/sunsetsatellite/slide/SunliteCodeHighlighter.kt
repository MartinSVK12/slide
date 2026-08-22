package sunsetsatellite.slide

import godot.annotation.Export
import godot.annotation.Script
import godot.api.CodeHighlighter
import godot.core.Color
import sunsetsatellite.sunlite.lang.Scanner
import sunsetsatellite.sunlite.lang.TokenType.TokenGroup.*

@Script
class SunliteCodeHighlighter: CodeHighlighter() {

	@Export val keywordColor: Color = Color("ff697d")
	@Export val typeKeywordColor: Color = Color.darkorange
	@Export val controlKeywordColor: Color = Color("f788c6")
	@Export val commentColor: Color = Color.webGray
	@Export val stringColor: Color = Color("e3d23d")

	init {
		numberColor = Color("0ddc79")
		symbolColor = Color("999999")
		functionColor = Color("62daf2")
		memberVariableColor = Color("e3cb8d")
		addColorRegion("//","",commentColor, true)
		addColorRegion("@","",typeKeywordColor,true)
		addColorRegion("\"","\"", stringColor, false)

		Scanner.keywords.forEach { (keyword, type) ->
			if(type.groups.contains(CONTROL)){
				addKeywordColor(keyword, controlKeywordColor)
			} else if(type.groups.contains(KEYWORDS)){
				addKeywordColor(keyword, keywordColor)
			} else if(type.groups.contains(TYPES)){
				addKeywordColor(keyword, typeKeywordColor)
			} else if(type.groups.contains(MODIFIERS)){
				addKeywordColor(keyword, keywordColor)
			}
		}
	}
}
