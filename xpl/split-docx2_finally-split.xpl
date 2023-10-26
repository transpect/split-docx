<?xml version="1.0" encoding="utf-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:pxf="http://exproc.org/proposed/steps/file"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub="http://transpect.io/docx2hub"
  xmlns:tr="http://transpect.io" 
  xmlns:html="http://www.w3.org/1999/xhtml" 
  version="1.0"
  name="actual-split-docx"
  type="tr:actual-split-docx">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>Will accept a <code>&lt;files></code> document as posted by the split button.</p>
  </p:documentation>

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>

  <p:input port="source" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Heading selection with @filename attributes in a <code>&lt;files></code> document. Example:</p>
      <pre><code>
        <file uri="file:/C:/cygwin/home/gerrit/Dev/spwf/content/split_test/b.docx" zip-manifest="file:/C:/cygwin/home/gerrit/Dev/spwf/content/split_test/out/b.docx.zip-manifest.xml" single-tree="file:///C:/cygwin/home/gerrit/Dev/spwf/content/split_test/out/b.docx.single-tree.xml">
          <style name="[no style]" id=""/>
          <style name="heading 1" id="berschrift1" split-as="chapter"/>
          <bookmark chapter="true" part="false"/>
          <headings>
            <unassigned/>
            <chapter style-name="heading 1" style-id="berschrift1" spec="style" srcpath="file:/C:/cygwin/home/gerrit/Dev/spwf/content/split_test/out/b.docx.tmp/word/document.xml?xpath=/w:document[1]/w:body[1]/w:p[29]" filename="A_0_001_Dedication">Ein praxisbezogenes Lehr- und Arbeitsbuch</chapter>
            <chapter style-name="heading 1" style-id="berschrift1" spec="style" srcpath="file:/C:/cygwin/home/gerrit/Dev/spwf/content/split_test/out/b.docx.tmp/word/document.xml?xpath=/w:document[1]/w:body[1]/w:p[110]" filename="A_0_002_Toc">Inhalt</chapter>
          </headings>
        </file>
    </code></pre>
    </p:documentation>
    <p:inline>
      <nodoc/>
    </p:inline>
  </p:input>
  <p:output port="result" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>The input document, enriched with the text and IDs of the found headings.</p>
    </p:documentation>
  </p:output>
  <p:serialization port="result" indent="true"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>

  <p:viewport match="file" name="spliteration">
    <p:output port="result" primary="true">
      <p:pipe port="result" step="id"></p:pipe>
    </p:output>
    <p:identity name="id"/>
    <p:choose>
      <p:when test="/file/@copy-as">
        <pxf:copy>
          <p:with-option name="href" select="/*/@uri"/>
          <p:with-option name="target" 
            select="concat(resolve-uri((/file/@filename, /file/headings/unassigned/@filename)[1], /*/@single-tree), '.docx')"/>
        </pxf:copy>
      </p:when>
      <p:when test="every $h in /file/headings/* satisfies ($h/self::unassigned[@filename])
                    or
                    exists(/*/headings/*/@filename)">
        <!-- The first condition above is equivalent could be handled by the plain copying operation above, 
          except for docm files. -->
        <p:xslt name="split-single-tree">
          <p:input port="stylesheet">
            <p:document href="../xsl/split-single-tree.xsl"/>
          </p:input>
          <p:input port="parameters"><p:empty/></p:input>
        </p:xslt>
        <p:sink/>
        <p:for-each name="individual-split-results">
          <p:iteration-source>
            <p:pipe port="secondary" step="split-single-tree"/>
          </p:iteration-source>
          <tr:store-debug name="store-split-single-trees">
            <p:with-option name="pipeline-step" select="concat('split/', replace(base-uri(/*), '^.+/(.+?/.+)/+$', '$1'))"/>
            <p:with-option name="active" select="$debug"/>
            <p:with-option name="base-uri" select="$debug-dir-uri"/>
          </tr:store-debug>
          
          <p:xslt name="export-xsl" cx:depends-on="store-split-single-trees">
            <p:input port="stylesheet">
              <p:document href="../xsl/export.xsl"/>
            </p:input>
            <p:input port="parameters"><p:empty/></p:input>
          </p:xslt>
          <p:sink/>
          <!--<cx:message>
            <p:input port="source">
              <p:pipe port="current" step="individual-split-results"/>
            </p:input>
            <p:with-option name="message" select="'SSSSSSSSSSSSS ', string-join(base-uri(/*), ' ')">
              <p:pipe port="secondary" step="export-xsl"/>
            </p:with-option>
            </cx:message>-->
          <p:for-each name="store-modified-archive-members">
            <p:documentation>Will overwrite the XML contents of the unzipped docx file
            with the splitting results.</p:documentation>
            <p:iteration-source>
              <p:pipe port="secondary" step="export-xsl"/>
            </p:iteration-source>
            <!--<cx:message>
              <p:with-option name="message" select="'NNNNNNNNNNNN ', base-uri(/)"/>
            </cx:message>-->
            <p:store>
              <p:with-option name="href" select="base-uri()"/>
            </p:store>
          </p:for-each>
          
          <p:xslt name="prune-zip-manifest">
            <p:input port="source">
              <p:pipe port="current" step="spliteration">
                <p:documentation>/file</p:documentation>
              </p:pipe>
              <p:pipe port="current" step="individual-split-results">
                <p:documentation>/w:root</p:documentation>
              </p:pipe>
            </p:input>
            <p:input port="parameters">
              <p:empty/>
            </p:input>
            <p:input port="stylesheet">
              <p:inline>
                <xsl:stylesheet version="2.0" 
                  xmlns:ct="http://schemas.openxmlformats.org/package/2006/content-types"
                  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships">
                  <xsl:variable name="remove" as="xs:string+" 
                    select="for $r in collection()[2]/w:root/w:docRels/rel:Relationships/rel:Relationship[@remove-resource]/@Target
                            return concat('word/', $r),
                            for $p in collection()[2]/w:root/w:docTypes/ct:Types/ct:Override[@remove-resource]/@PartName
                            return substring($p, 2),
                            collection()[2]/w:root/w:containerRels/rel:Relationships/rel:Relationship[@remove-resource]/@Target,
                            'word/_rels/customizations.xml.rels',
                            'word/_rels/vbaProject.bin.rels'"/>
                  <xsl:template match="/file">
                    <xsl:apply-templates select="doc(@zip-manifest)"/>
                  </xsl:template>
                  <xsl:template match="* | @*">
                    <xsl:copy>
                      <xsl:apply-templates select="@*, node()"/>
                    </xsl:copy>
                  </xsl:template>
                  <xsl:template match="c:zip-manifest">
                    <xsl:next-match/>
                  </xsl:template>
                  <xsl:template match="c:entry[@name = $remove]"/>
                </xsl:stylesheet>
              </p:inline>
            </p:input>
          </p:xslt>
          
          <p:sink/>
          
          <cx:zip compression-method="deflated" compression-level="default" command="create" name="zip"
            cx:depends-on="store-modified-archive-members">
            <p:with-option name="href" select="replace(base-uri(), '\.xml$', '.docx')">
              <p:pipe port="current" step="individual-split-results"/>
            </p:with-option>
            <p:input port="source">
              <p:empty/>
            </p:input>
            <p:input port="manifest">
              <p:pipe step="prune-zip-manifest" port="result"/>
            </p:input>
          </cx:zip>
          
        </p:for-each>
        <p:sink/>
      </p:when>
      <p:otherwise>
        <p:sink/>
      </p:otherwise>
    </p:choose>
  </p:viewport>

</p:declare-step>
