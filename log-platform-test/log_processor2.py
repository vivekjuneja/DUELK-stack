# -*- coding: utf-8 -*-

import sys
import re

# Used for matching a valid Trace ID based on UUID v4 pattern
TRACEID_REGEX='[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}'

TRACEIDNOTAVAILABLE_STRING = 'TraceIdNotAvailable'

f = open(sys.argv[1], 'r', encoding="utf-8")
counter=0
newLineCounter=0;
pattern=sys.argv[2]
newParentLogFound=False
for line in f:
	# If the line begins with new line, we ignore that
	if(line.startswith("\n")):
		continue
	# If the line contains the pattern we are searching
	if(pattern in line):
		print(line, end='')
		# This is the start of a possible multline log, anything that appears after this can be a multline except another Traceid occurence
		newParentLogFound=True
	else:
		# If the pattern is not found, but its a part of the multiline, then continue
		if(newParentLogFound==True):
			# If the line does not contain another TRACEID, then print it out
			if( not re.search(TRACEID_REGEX, line) and not TRACEIDNOTAVAILABLE_STRING in line) :
				print(line, end='')
			else:
				# If the line does container another TRACEID, then this means that we need to ignore this line
				newParentLogFound=False
