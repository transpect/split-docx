<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  version="2.0">


  <xsl:param name="part-regex" select="''" required="false"/>
  <xsl:param name="chapter-regex" select="''" required="false"/>


  <xsl:template match="@* | node()" mode="add-split-as add-filename" priority="-0.5">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="*:file/*:style/@name" mode="add-split-as" priority="5">
    <xsl:variable name="style-name" select="." as="xs:string"/>
    <!--  <xsl:message select="'### split-docx config:  chapter-regex: ', $chapter-regex, ' part-regex:',  $part-regex"/>-->
    <xsl:next-match/>
    <xsl:for-each select="$part-regex[normalize-space()], $chapter-regex[normalize-space()]">
      <xsl:if test="matches($style-name, .)">
        <xsl:attribute name="split-as" select="if (. = $part-regex) then 'part' else 'chapter'"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="*:file" mode="add-filename">
    <xsl:next-match>
      <xsl:with-param name="target-basename" tunnel="yes" as="xs:string" select="replace(@uri, '^.+/(.+).do[ct][xm]$', '$1')"/>
      <xsl:with-param name="headings" tunnel="yes" as="element()*" select="./*:headings//*[@srcpath]"/>
    </xsl:next-match>
  </xsl:template>

  <xsl:template match="*:file/*:headings/*/@srcpath" mode="add-filename">
    <xsl:param name="target-basename" tunnel="yes" as="xs:string"/>
    <xsl:param name="headings" tunnel="yes" as="element()*"/>
    <xsl:next-match/>
    <xsl:attribute name="filename" select="concat($target-basename, '_', format-number(index-of($headings/@srcpath, .), '000'))"/>
  </xsl:template>


  
</xsl:stylesheet>