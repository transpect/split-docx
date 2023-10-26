# split-docx
this module helps with splitting docx files

* The main pipeline supports splitting on part and chapter headings. Their styles can be given as options `chapter-regex` and `part-regex`.
* Example invocation to split all docx files in a directory on paragraphs with style 'heading 1':
  `calabash/calabash.sh -o result=file:///C:/…/result.xml  split-docx/xpl/split-main.xpl dir=path-to-docx-dir chapter-regex="heading\s*1" debug=yes debug-dir-uri=file:///…/debug`

You could provide customer specific `split-docx/conf.xsl` filed to change target file names of splitted chunks. Therefore the pipeline must be invoked with a params input port.

The subpipelines can also be used to split on Bookmarks etc.
