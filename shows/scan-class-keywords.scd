// scan for class names

(
var root = thisProcess.nowExecutingPath.dirname,
match = "*contents.scd",
classNames = IdentitySet.new.addAll(Class.allClasses.collect(_.name)),
usedClasses = IdentitySet.new,
symbols = Set.new,
classRegexps = ["^[A-Z][A-Za-z0-9_]*", "[^A-Za-z0-9_][A-Z][A-Za-z0-9_]*"],
symbolRegexps = ["'[A-Za-z0-9_]*'", "\\\\[A-Za-z0-9_]*"],
stream = Post,

scanDirectoryTree = { |path|
	// depth first: descend into directories
	(path +/+ "*/").pathMatch.do { |p| scanDirectoryTree.(p) };
	// now handle scd's here
	(path +/+ match).pathMatch.do { |p| scanFile.(p) };
},

scanFile = { |path|
	var file = File(path, "r"), line;
	protect {
		while { (line = file.getLine).notNil } {
			classRegexps.do { |regexp|
				line.findRegexp(regexp).do { |match|
					match = match[1];
					if(match[0].isUpper.not) { match = match.drop(1) };
					match = match.asSymbol;
					if(classNames.includes(match)) {
						usedClasses.add(match);
					};
				};
			};
			symbolRegexps.do { |regexp|
				line.findRegexp(regexp).do { |match|
					symbols.add(match[1]);
				};
			};
		};
	} { file.close };
};

scanDirectoryTree.(root);

usedClasses.do { |name, i|
	if(i > 0) { stream << "," };
	stream << name;
};
stream << "\nemph={";
symbols.do { |symbol, i|
	if(i > 0) { stream << "," };
	stream << symbol;
};
stream << "},emphstyle={\\color{symbolgreen}}\n";
)