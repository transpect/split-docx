<?xml version="1.0" encoding="utf-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub="http://transpect.io/docx2hub"
  xmlns:tr="http://transpect.io" 
  xmlns:html="http://www.w3.org/1999/xhtml" 
  version="1.0"
  name="split-docx_scan-dir" 
  type="tr:split-docx_scan-dir">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>This step will report the paragraph styles for all docx files in a given directory.</p>
  </p:documentation>

  <p:option name="dir" required="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Input directory, given as a path or as a URI.</p>
    </p:documentation>
  </p:option>
  <p:option name="outdir" required="false" select="''">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Directory for transient and output files, given as a path or as a URI.
      If empty, will be set to '{$dir}/out/'.</p>
    </p:documentation>
  </p:option>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>

  <p:output port="result" primary="true"/>
  <p:serialization port="result" indent="true" omit-xml-declaration="false"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/docx2hub/xpl/single-tree.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>

  <tr:file-uri name="output-dir-uri">
    <p:with-option name="filename" select="concat( ($outdir[not(. = '')], concat($dir, '/out'))[1], '/')"/>
  </tr:file-uri>

  <p:sink/>

  <tr:file-uri name="input-dir-uri">
    <p:with-option name="filename" select="$dir"/>
  </tr:file-uri>

  <p:directory-list include-filter="^.+\.do[ct][mx]" name="list-input-files">
    <p:with-option name="path" select="/c:result/@local-href"/>
  </p:directory-list>

  <p:xslt name="sort">
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0">
          <xsl:template match="c:directory">
            <xsl:copy>
              <xsl:copy-of select="@*"/>
              <xsl:apply-templates select="c:file">
                <xsl:sort select="@name" collation="http://saxon.sf.net/collation?lang=de;strength=primary"/>
              </xsl:apply-templates>
            </xsl:copy>
          </xsl:template>
          <xsl:template match="c:file">
            <xsl:copy>
              <xsl:attribute name="name" select="resolve-uri(@name, base-uri(/*))"/>
            </xsl:copy>
          </xsl:template>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
  </p:xslt>

  <p:choose>
    <p:when test="/c:directory/c:file">
      <p:for-each name="single-tree-iteration">
        <p:iteration-source select="/c:directory/c:file"/>
        <p:output port="result" primary="true">
          <p:pipe port="result" step="zip-manifest-uri"/>
        </p:output>
        <p:variable name="basename" select="replace(/c:file/@name, '^.+/', '')">
          <p:pipe step="single-tree-iteration" port="current"/>
        </p:variable>
        <p:variable name="outdir-basename" select="concat(/c:result/@os-path, '/', $basename)">
          <p:pipe step="output-dir-uri" port="result"/>
        </p:variable>
        <docx2hub:single-tree name="st" srcpaths="yes">
          <p:with-option name="docx" select="/*/@name">
            <p:pipe port="current" step="single-tree-iteration"/>
          </p:with-option>
          <p:with-option name="extract-dir" select="concat(/c:result/@os-path, '/', $basename, '.tmp')">
            <p:pipe step="output-dir-uri" port="result"/>
          </p:with-option>
          <p:with-option name="debug" select="$debug"/>
          <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
          <p:input port="xslt">
            <p:inline>
              <xsl:stylesheet version="2.0">
                <xsl:import href="http://transpect.io/docx2hub/xsl/main.xsl"/>
                <xsl:variable name="docx2hub:srcpath-elements" as="xs:string+" select="( 'w:p' )"/>
              </xsl:stylesheet>
            </p:inline>
          </p:input>
        </docx2hub:single-tree>

        <p:add-attribute match="/*" attribute-name="storage-uri" name="storage-uri">
          <p:with-option name="attribute-value" select="concat(/c:result/@local-href, $basename, '.single-tree.xml')">
            <p:pipe step="output-dir-uri" port="result"/>
          </p:with-option>
        </p:add-attribute>

        <p:add-attribute match="/*" attribute-name="zip-manifest-uri" name="zip-manifest-uri">
          <p:with-option name="attribute-value" select="concat(/c:result/@local-href, $basename, '.zip-manifest.xml')">
            <p:pipe step="output-dir-uri" port="result"/>
          </p:with-option>
        </p:add-attribute>

        <p:store omit-xml-declaration="false" indent="true">
          <p:with-option name="href" select="/w:root/@storage-uri"/>
        </p:store>

        <p:store omit-xml-declaration="false" indent="true">
          <p:with-option name="href" select="/w:root/@zip-manifest-uri">
            <p:pipe port="result" step="zip-manifest-uri"/>
          </p:with-option>
          <p:input port="source">
            <p:pipe port="zip-manifest" step="st"/>
          </p:input>
        </p:store>

      </p:for-each>

      <p:xslt name="extract">
        <p:input port="source">
          <p:pipe port="result" step="single-tree-iteration"/>
        </p:input>
        <p:input port="parameters">
          <p:empty/>
        </p:input>
        <p:input port="stylesheet">
          <p:inline>
            <xsl:stylesheet version="2.0">
              <xsl:template match="/">
                <files>
                  <xsl:apply-templates select="collection()/*"/>
                </files>
              </xsl:template>
              <xsl:key name="pstyle-by-id" match="w:styles/w:style[@w:type='paragraph']" use="@w:styleId"/>
              <xsl:template match="/w:root">
                <file uri="{@local-href}" single-tree="{@storage-uri}" zip-manifest="{@zip-manifest-uri}">
                  <xsl:for-each-group select="w:document/w:body/w:p" group-by="(w:pPr/w:pStyle/@w:val, '')[1]">
                    <xsl:variable name="style" select="key('pstyle-by-id', current-grouping-key(), root(.))"
                      as="element(w:style)?"/>
                    <style name="{($style/w:name/@w:val, '[no style]')[1]}" id="{$style/@w:styleId}"/>
                  </xsl:for-each-group>
                  <xsl:copy-of select="/c:files"/>
                </file>
              </xsl:template>
            </xsl:stylesheet>
          </p:inline>
        </p:input>
      </p:xslt>
    </p:when>

    <p:otherwise>
      <cx:message>
        <p:with-option name="message" select="'No docx, docm, dotx, or dotm files in directory.'"/>
      </cx:message>
    </p:otherwise>

  </p:choose>

</p:declare-step>
