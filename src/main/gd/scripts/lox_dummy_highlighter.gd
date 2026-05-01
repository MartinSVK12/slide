extends Node
class_name LoxStaticCodeHighlighter

var keywords := ["and", "class", "else", "false", "for", "fun", "init", "if", "nil", "or", "return", "super", "this", "true", "var", "while", "break", "continue", "static", "native", "interface", "is", "isnt", "import", "dynamic", "any", "string", "number", "boolean", "function", "array", "as", "extends", "implements", "try", "catch", "throw"]

var cache: Array[LineCache] = []
var colors: Dictionary = {}

@onready var t: TextEdit = $".."

var update = 0
var update_threshold = 250

signal send_update(d: Dictionary)

func _init() -> void:
	colors[G.NONE] = Color.WHITE
	colors[G.KEYWORD] = Color.ORANGE
	colors[G.TYPE] = Color.MEDIUM_SPRING_GREEN
	colors[G.TYPE_PARAM] = Color.LIGHT_SEA_GREEN
	colors[G.CONSTANT] = Color.LIGHT_CORAL
	colors[G.STRING] = Color.KHAKI
	colors[G.NUMBER] = Color.PALE_GREEN
	colors[G.COMMENT] = Color.LIGHT_GRAY
	colors[G.FUNCTION] = Color.SKY_BLUE
	colors[G.CLASS_NAME] = Color.SKY_BLUE
	colors[G.PROPERTY_DECL] = Color.HOT_PINK
	colors[G.SYMBOL] = Color.DARK_GRAY

func _ready() -> void:
	(t.syntax_highlighter as LoxHighlighterBase).request_update.connect(return_highlighting_data)
	update_cache()

func return_highlighting_data(line: int):
	var c: Array[LineCache] = cache.filter(func(e: LineCache): return e.line == line)
	if(c.is_empty()): return { 0: {"color": Color.LIGHT_GRAY}}
	var comment = t.text.split('\n')[line]
	if(comment.contains("//")): return { comment.find("//"): {"color": Color.DIM_GRAY}}
	var d = {}
	for lc in c:
		d[lc.start] = {"color": colors[lc.type]}
		d[lc.end] = {"color": Color.LIGHT_GRAY}
	
	(t.syntax_highlighter as LoxHighlighterBase).cache = d

func update_cache() -> void:
	cache.clear()
	
	highlight(r'\b(and|class|else|false|for|fun|init|if|nil|or|return|super|this|true|var|while|break|continue|static|native|interface|is|isnt|import|dynamic|any|string|number|boolean|function|array|as|extends|implements|try|catch|throw|generic)\b',{1: G.KEYWORD})
	
	#highlight(r'\b(static|native|dynamic)\b',{1: G.KEYWORD})

	#class, interface definitions
	#highlight(r'\b((class)(<([A-Za-z0-9_,\\s]*),?>)?)\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*(extends)\s*([A-Za-z_][A-Za-z0-9_]*))?(?:\s*(implements)\s*([A-Za-z_][A-Za-z0-9_]*))?\b',{2:G.KEYWORD,4:G.TYPE_PARAM,5:G.CLASS_NAME,6:G.KEYWORD,7:G.CLASS_NAME,8:G.KEYWORD,9:G.CLASS_NAME})
	#highlight(r'\b((interface)(<([A-Za-z0-9_,\\s]*),?>)?)\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*(implements)\s*([A-Za-z_][A-Za-z0-9_]*))?\b',{2:G.KEYWORD,4:G.TYPE_PARAM,5:G.CLASS_NAME,6:G.KEYWORD,7:G.CLASS_NAME})

	#some keywords again
	#highlight(r'\b(if|else|while|for|fun)\b',{1: G.KEYWORD})

	#variables
	#highlight(r'\b(static\s)?(var)\s+([A-Za-z_][A-Za-z0-9_]*)\b',{1: G.KEYWORD, 2: G.KEYWORD, 3: G.NONE})

	#variable declaration
	#highlight(r'\b(var)\s+\b',{1: G.KEYWORD})
	#highlight(r'(for|while|if)\(var\s+.+:\s+([^\<\>]+)\s+=\s+([0-9]+(?:.[0-9]+)?+);',{2: G.TYPE, 3: G.NUMBER})
	#highlight(r'(for|while|if)\(var\s+.+:\s+(<(.*)>)\s+=\s+([0-9]+(?:.[0-9]+)?+);',{3: G.TYPE_PARAM, 4: G.NUMBER})
	#highlight(r'(for|while|if)\(var\s+([^:])\s+=\s+([0-9]+(?:.[0-9]+)?+);',{2: G.NONE, 3: G.NUMBER})

	#functions
	#highlight(r'(native)\s((?!if\(|for\(|while\(\b)\b\w+)\(.*?\)',{1: G.KEYWORD, 2: G.FUNCTION})
	#highlight(r'(fun)\s((?!if\(|for\(|while\(\b)\b\w+)\(.*?\)\s?{',{1: G.KEYWORD, 2: G.FUNCTION})
	#highlight(r'(fun)\s((?!if\(|for\(|while\(\b)\b\w+)\(.*?\)',{1: G.KEYWORD, 2: G.FUNCTION})
	#highlight(r'((?!if\(|for\(|while\(\b)\b\w+)\(.*?\):',{1:G.FUNCTION})
	#highlight(r'[^\.]((?!if\(|for\(|while\(\b)\b\w+)\(.*?\)\s?(?!\)|\;)',{1:G.FUNCTION})


	#parameters, local variables and their types
	#highlight(r'(([a-zA-Z_][a-zA-Z_0-9]*):\s*(([a-zA-Z_][a-zA-Z_0-9]*\s*\|?\s*)*)?|(<([a-zA-Z_][a-zA-Z_0-9,\s]*)>(\|[^<>\s\)\{\},]+|\?)?(\|)?))',{2: G.PROPERTY_DECL, 3: G.TYPE, 6: G.TYPE_PARAM, 7: G.TYPE},"vars")

	#type parameters
	#highlight(r'(<([a-zA-Z_][a-zA-Z_0-9]*)>)(\|[^<>\s\)\{\}]+|\?)?(\|)?',{2: G.TYPE_PARAM, 3: G.TYPE, 4: G.TYPE})

	#return values
	#highlight(r'\):(\s*?[a-zA-Z_][a-zA-Z_0-9]*(?:\s*\|?\s*[a-zA-Z_][a-zA-Z_0-9]*)*)',{1: G.TYPE})

	#strings
	#highlight(r'\b(print)\b',{0: G.NONE})
	#highlight(r'(import)\s+(\".*\")', {1: G.KEYWORD, 2: G.STRING})
	#highlight(r'(print)\s+(\".*\")', {1: G.NONE, 2: G.STRING})
	highlight(r'\".*\"', {0: G.STRING})

	#keywordss
	#highlight(r'(this|super|(return))',{1: G.CONSTANT, 2: G.KEYWORD})
	#highlight(r'\b(if|else|while|for|and|or|break|continue|is|isnt|as|import|fun|implements|extends)\b',{1: G.KEYWORD})

	#boolean
	highlight(r'\b(true|false)\b',{0: G.CONSTANT})

	#numbers
	highlight(r'\b[0-9]+(?:.[0-9]+)?\b', {0: G.NUMBER})

	#nil
	highlight(r'nil[^\s,|\)]', {0: G.CONSTANT})

	cache = cache.filter(func(e: LineCache): return e.string != "" && e.start != -1 && e.end != -1)
	
	(t.syntax_highlighter as LoxHighlighterBase).clear_highlighting_cache()
	(t.syntax_highlighter as LoxHighlighterBase).update_cache()


func highlight(regex: String, types: Dictionary, special: String = "") -> void:
	var r = RegEx.create_from_string(regex)
	var lines = t.text.split('\n')
	var i = 0
	for l in lines:
		var matches: Array[RegExMatch] = r.search_all(l)
		for m in matches:
			for key in types:
				var value = types[key]
				cache.append(LineCache.new(i,m.get_string(key),m.get_start(key),m.get_end(key),value))
		i += 1

class LineCache:
	var type: G = G.NONE
	var line := 0
	var string := ""
	var start := 0
	var end := 0
	
	func _init(l: int,s: String,b: int,e: int,g: G) -> void:
		self.line = l
		self.string = s
		self.start = b
		self.end = e
		self.type = g
		
	func _to_string() -> String:
		return "'{0}' at [{1}::({2}:{3})] ({4})".format([string,line,start,end,type])

enum G {
	NONE,
	KEYWORD,
	TYPE,
	TYPE_PARAM,
	CONSTANT,
	STRING,
	NUMBER,
	COMMENT,
	FUNCTION,
	PROPERTY_DECL,
	SYMBOL,
	CLASS_NAME
}

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		update_cache()

func _on_timer_timeout() -> void:
	update_cache()
