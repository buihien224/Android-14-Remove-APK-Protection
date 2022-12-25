import sys	
from configobj import ConfigObj

# Functions
# Author : @trungmmmmt

def lineNumByPhrase(phrase, source, isText=0, startsAt=0):
	if isText:
		if isText == 1 or isText == True:
			source = source.splitlines()
		for (i, line) in enumerate(source):
			if i >= startsAt and line.startswith(phrase):
				return i
	else:
		with open(source, 'r') as f:
			return lineNumByPhrase(phrase, f, 2, startsAt)
	return -1


def fileReplaceRange(filename, startIndex, endIndex, content):
	lines = []
	with open(filename, 'r') as f:
		lines = f.readlines()

	with open(filename, 'w') as f:
		wrote = False
		for i, line in enumerate(lines):
			if i not in range(startIndex, endIndex + 1):
				f.write(line)
			else:
				if not wrote:
					f.write(content + '\n')
					wrote = True


# Main script
# Loading configs

for i, arg in enumerate(sys.argv):
	if i > 0:
		ini = ConfigObj(str(sys.argv[1]))
		config = ini['main']
		replaceFile = str(sys.argv[2])
		phraseStart = config['phraseStart']
		phraseEnd = config['phraseEnd']
		replaceWith = config['replaceWith']
		startIndex = lineNumByPhrase(phraseStart, replaceFile)
		endIndex = lineNumByPhrase(phraseEnd, replaceFile, 0, startIndex)
		fileReplaceRange(replaceFile, startIndex, endIndex, replaceWith)
