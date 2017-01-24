# -*- coding: utf-8 -*-

import sys

f = open('raw_log_3', 'r', encoding="utf-8")
counter=0
newLineCounter=0;
pattern=sys.argv[1]
isMultiline=False
for line in f:
	if((pattern in line) or (isMultiline)):
		if(line.startswith('\n')):
			isMultiline=False
			continue;
		else:
			print(line,end='')
			isMultiline=True
	if counter > 100000:
		sys.exit(0)
	counter+=1
