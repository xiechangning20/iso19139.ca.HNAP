<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Copyright (C) 2001-2016 Food and Agriculture Organization of the
  ~ United Nations (FAO-UN), United Nations World Food Programme (WFP)
  ~ and United Nations Environment Programme (UNEP)
  ~
  ~ This program is free software; you can redistribute it and/or modify
  ~ it under the terms of the GNU General Public License as published by
  ~ the Free Software Foundation; either version 2 of the License, or (at
  ~ your option) any later version.
  ~
  ~ This program is distributed in the hope that it will be useful, but
  ~ WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  ~ General Public License for more details.
  ~
  ~ You should have received a copy of the GNU General Public License
  ~ along with this program; if not, write to the Free Software
  ~ Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
  ~
  ~ Contact: Jeroen Ticheler - FAO - Viale delle Terme di Caracalla 2,
  ~ Rome - Italy. email: geonetwork@osgeo.org
  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:gco="http://www.isotc211.org/2005/gco"
                xmlns:srv="http://www.isotc211.org/2005/srv"
                xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:gml="http://www.opengis.net/gml/3.2"
                xmlns:gml320="http://www.opengis.net/gml"
                xmlns:gn="http://www.fao.org/geonetwork"
                xmlns:gn-fn-core="http://geonetwork-opensource.org/xsl/functions/core"
                xmlns:gn-fn-iso19139="http://geonetwork-opensource.org/xsl/functions/profiles/iso19139"
                exclude-result-prefixes="#all"
                version="2.0">

  <xsl:import href="utility-fn.xsl"/>

  <xsl:template mode="csv" match="gmd:MD_Metadata|*[@gco:isoType='gmd:MD_Metadata']"
                priority="10">
    <xsl:variable name="langId" select="gn-fn-iso19139:getLangIdHNAP(., $lang)"/>
    <xsl:variable name="info" select="gn:info"/>
    <xsl:variable name="codelists" select="document('../loc/eng/codelists.xml')/codelists"/>

    <metadata>
      <title>
        <xsl:apply-templates mode="localised"
                             select="gmd:identificationInfo/*/gmd:citation/*/gmd:title">
          <xsl:with-param name="langId" select="$langId"/>
        </xsl:apply-templates>
      </title>
      <abstract>
        <xsl:apply-templates mode="localised" select="gmd:identificationInfo/*/gmd:abstract">
          <xsl:with-param name="langId" select="$langId"/>
        </xsl:apply-templates>
      </abstract>

      <category>
        <xsl:choose>
          <xsl:when test="gmd:identificationInfo/srv:SV_ServiceIdentification">service</xsl:when>
          <xsl:otherwise>dataset</xsl:otherwise>
        </xsl:choose>
      </category>
      <metadatacreationdate>
        <xsl:value-of select="gmd:dateStamp/*"/>
      </metadatacreationdate>
      <referencesystem>
        <xsl:value-of select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:code/gco:CharacterString"/>
      </referencesystem>

      <!-- For each date grouped by the date type mapped to a readable value -->
      <xsl:for-each select="gmd:identificationInfo/*/gmd:citation/*/gmd:date">
        <xsl:variable name="dateTypeCode" select="*/gmd:dateType/*/@codeListValue"/>
        <xsl:variable name="dateTypeCodeReadable" select="tokenize($codelists/codelist[@name = 'gmd:CI_DateTypeCode']/entry[code/text() = $dateTypeCode]/value/text(), ';')[1]"/>

        <xsl:element name="date-{$dateTypeCodeReadable}">
          <xsl:value-of select="*/gmd:date/*/text()"/>
        </xsl:element>
      </xsl:for-each>

      <xsl:for-each select="gmd:identificationInfo/*/gmd:graphicOverview/*/gmd:fileName">
        <image>
          <xsl:value-of select="*/text()"/>
        </image>
      </xsl:for-each>

      <!-- All descriptive keywords -->
      <xsl:for-each select="gmd:identificationInfo/*/gmd:descriptiveKeywords/*">
        <xsl:variable name="keywordTypeCode" select="gmd:type/*/@codeListValue"/>
        <xsl:variable name="keywordTypeCodeReadable" select="tokenize($codelists/codelist[@name = 'gmd:MD_KeywordTypeCode']/entry[code/text() = $keywordTypeCode]/value/text(), ';')[1]"/>
        <xsl:variable name="thesaurusKey" select="normalize-space(replace(gmd:thesaurusName/*/gmd:identifier/*/gmd:code/*/text(), '[^a-zA-Z0-9]', ''))"/>

        <xsl:choose>
          <!-- All keywords with a valid thesaurus name -->
          <xsl:when test="$thesaurusKey != ''">
            <xsl:for-each select="gmd:keyword[not(@gco:nilReason) or */text() != '']">
              <xsl:element name="keyword-{$thesaurusKey}">
                <xsl:apply-templates mode="localised" select=".">
                  <xsl:with-param name="langId" select="$langId"/>
                </xsl:apply-templates>
              </xsl:element>
            </xsl:for-each>
          </xsl:when>
          <!-- All keywords with a valid keywordTypeCode -->
          <xsl:when test="$keywordTypeCodeReadable != ''">
            <xsl:for-each select="gmd:keyword[not(@gco:nilReason) or */text() != '']">
              <xsl:element name="keyword-{$keywordTypeCodeReadable}">
                <xsl:apply-templates mode="localised" select=".">
                  <xsl:with-param name="langId" select="$langId"/>
                </xsl:apply-templates>
              </xsl:element>
            </xsl:for-each>
          </xsl:when>
          <!-- All keywords without a valid thesaurusName or keywordTypeCode -->
          <xsl:otherwise>
            <xsl:for-each select="gmd:keyword[not(@gco:nilReason) or */text() != '']">
              <keyword-other>
                <xsl:apply-templates mode="localised" select=".">
                  <xsl:with-param name="langId" select="$langId"/>
                </xsl:apply-templates>
              </keyword-other>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

      <!-- One column per role code -->
      <xsl:for-each select="gmd:identificationInfo/*/gmd:pointOfContact">
        <xsl:variable name="roleCode" select="*/gmd:role/*/@codeListValue"/>
        <xsl:variable name="roleCodeReadable" select="tokenize($codelists/codelist[@name = 'gmd:CI_RoleCode']/entry[code/text() = $roleCode]/value/text(), ';')[1]"/>

        <xsl:element name="contact-{$roleCodeReadable}">
          <xsl:apply-templates mode="localised" select="*/gmd:organisationName">
            <xsl:with-param name="langId" select="$langId"/>
          </xsl:apply-templates>/
          <xsl:apply-templates mode="localised" select="*/gmd:contactInfo/*/gmd:address/*/gmd:electronicMailAddress">
            <xsl:with-param name="langId" select="$langId"/>
          </xsl:apply-templates>
        </xsl:element>
      </xsl:for-each>

      <xsl:for-each select="gmd:identificationInfo/*/gmd:extent/*/gmd:geographicElement/gmd:EX_GeographicBoundingBox">
        <geoBox>
          <westBL>
            <xsl:value-of select="gmd:westBoundLongitude"/>
          </westBL>
          <eastBL>
            <xsl:value-of select="gmd:eastBoundLongitude"/>
          </eastBL>
          <southBL>
            <xsl:value-of select="gmd:southBoundLatitude"/>
          </southBL>
          <northBL>
            <xsl:value-of select="gmd:northBoundLatitude"/>
          </northBL>
        </geoBox>
      </xsl:for-each>


      <xsl:for-each select="gmd:identificationInfo/*/*/gmd:MD_Constraints/*">
        <Constraints>
          <xsl:copy-of select="."/>
        </Constraints>
      </xsl:for-each>

      <xsl:for-each select="gmd:identificationInfo/*/*/gmd:MD_SecurityConstraints/*">
        <SecurityConstraints>
          <xsl:choose>
            <xsl:when test="*/@codeListValue">
              <xsl:variable name="classificationCode" select="*/@codeListValue"/>
              <xsl:variable name="classificationCodeReadable" select="tokenize($codelists/codelist[@name = 'gmd:MD_ClassificationCode']/entry[code/text() = $classificationCode]/value/text(), ';')[1]"/>
              <xsl:value-of select="$classificationCodeReadable"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="*/text()"/>
            </xsl:otherwise>
          </xsl:choose>
        </SecurityConstraints>
      </xsl:for-each>

      <xsl:for-each select="gmd:identificationInfo/*/*/gmd:MD_LegalConstraints/*">
        <LegalConstraints>
          <xsl:choose>
            <xsl:when test="*/@codeListValue">
              <xsl:variable name="restrictionCode" select="*/@codeListValue"/>
              <xsl:variable name="restrictionCodeReadable" select="tokenize($codelists/codelist[@name = 'gmd:MD_RestrictionCode']/entry[code/text() = $restrictionCode]/value/text(), ';')[1]"/>
              <xsl:value-of select="$restrictionCodeReadable"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="*/text()"/>
            </xsl:otherwise>
          </xsl:choose>
        </LegalConstraints>
      </xsl:for-each>


      <xsl:for-each select="gmd:distributionInfo//gmd:linkage">
        <link>
          <xsl:value-of select="*/text()"/>
        </link>
      </xsl:for-each>
      <xsl:for-each select="gmd:distributionInfo//gmd:distributionFormat/*/gmd:name">
        <format>
          <xsl:apply-templates mode="localised" select=".">
            <xsl:with-param name="langId" select="$langId"/>
          </xsl:apply-templates>
        </format>
      </xsl:for-each>

      <xsl:copy-of select="gn:info"/>
    </metadata>

  </xsl:template>
</xsl:stylesheet>
