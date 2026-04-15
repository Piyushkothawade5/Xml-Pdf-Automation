<?xml version="1.0" encoding="UTF-8"?>
<!-- CTAnalyzer.xsl-->
<!-- CT-Analyzer Reporting Stylesheet-->
<!-- Version 4.40  -  18.06.2014 AndCla -->
<!-- (c) 2004-2014 OMICRON electronics GmbH, Austria-->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="html" />

	<!-- ********** Global includes for other files ********** -->

	<!-- ********** Global parameter definition ********** -->
	<xsl:param name="styleSheetVersion">4.40 (2014-06-18)</xsl:param>
	<xsl:param name="reportDate" select="//Object[CPLine = 'CT-Analyzer']/Tests/General/Time" />
	<xsl:param name="omicronDevice" select="//Object[CPLine = 'CT-Analyzer']/CPLine/text()" />

	<xsl:param name="standard" select="//Object[CPLine = 'CT-Analyzer']/TestObject/Standard" />
	<xsl:param name="standardName">
		<!--rename all ANSI standards to IEEE-->
		<xsl:if test="starts-with(//Object[CPLine = 'CT-Analyzer']/TestObject/Standard , 'ANSI')">
			<IDTag rid="CARD_GENERAL_020">IEEE C57.13</IDTag>
		</xsl:if>
		<!--rename 60044 standards to IEC-->
		<xsl:if test="starts-with(//Object[CPLine = 'CT-Analyzer']/TestObject/Standard,'60044')">
			<xsl:value-of select="concat('IEC ',//Object[CPLine = 'CT-Analyzer']/TestObject/Standard)" />
		</xsl:if>
		<!--rename 61869-2 standard to IEC-->
		<xsl:if test="starts-with(//Object[CPLine = 'CT-Analyzer']/TestObject/Standard,'61869')">
			<xsl:value-of select="concat('IEC ',//Object[CPLine = 'CT-Analyzer']/TestObject/Standard)" />
		</xsl:if>
	</xsl:param>

	<xsl:param name="coreType" select="//Object[CPLine = 'CT-Analyzer']/TestObject/CoreType" />
	<xsl:param name="ratioType" select="//Object[CPLine = 'CT-Analyzer']/RatioType" />
	<xsl:param name="class" select="//Object[CPLine = 'CT-Analyzer']/TestObject/Class[.!= '?']" />
	<xsl:param name="frequency" select="//Object[CPLine = 'CT-Analyzer']/TestObject/Frequency/Displ" />
	<xsl:param name="nominalPower" select="concat(format-number(//Object[CPLine = 'CT-Analyzer']/TestObject/NominalPower/Power/Val,'#0.0#'),' VA')" />
	<xsl:param name="nominalBurden" select="concat(format-number(//Object[CPLine = 'CT-Analyzer']/TestObject/NominalBurden/Power/Val,'#0.0#'),' VA')" />
	<xsl:param name="ctRatio">
		<xsl:value-of select="format-number(//Object[CPLine = 'CT-Analyzer']/TestObject/Ipn/Val,'#')" />:<xsl:value-of select="format-number(//Object[CPLine = 'CT-Analyzer']/TestObject/Isn/Val,'#')" />
	</xsl:param>
	<xsl:param name="secondaryResistance">
		<xsl:value-of select="format-number(//Object[CPLine = 'CT-Analyzer']/TestObject/Rct/Val, '#0.000')" />&#8486; (<xsl:value-of select="//Object[CPLine = 'CT-Analyzer']/Tests/Cards/Resistance/Settings/Tref/Displ" />)
	</xsl:param>

	<!-- for compatibility issues to older cta report versions -->
	<xsl:param name="isIeeeStandard">
		<xsl:choose>
			<xsl:when test="//Object[CPLine = 'CT-Analyzer']/TestObject/Standard = 'ANSI 45'">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:when test="//Object[CPLine = 'CT-Analyzer']/TestObject/Standard = 'ANSI 30'">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	<xsl:param name="assessmentResultOverAllFailed" select="count(*//Assessments/*/Auto[.=-1])" />

	<xsl:param name="AL_activation">
		<IDTag rid="PARAMETER_SHOW_AL_ERROR_GRAPH">FALSE</IDTag>
	</xsl:param>
	<xsl:param name="enableErrorGraph" select="contains($AL_activation,'TRUE')" />



	<!-- ********** Start for XSL transformation, this template is applied for the root element of the XML document ********** -->
	<xsl:template match="/" name="document_root">
		<xsl:apply-templates />
	</xsl:template>


	<!-- This template calls a template for each card in the report -->
	<!-- You may comment or uncomment each card, reorder is possible -->
	<xsl:template match="Object[CPLine = 'CT-Analyzer']" name="Object_CT-Analyzer">

		<!-- Begin HTML-->
		<html>

			<!-- call HTML header settings-->
			<xsl:call-template name="html_head" />

			<!-- Begin HTML body-->
			<body>
				<!-- apply all necessary templates-->
				<xsl:call-template name="General_Device_Data" />
				<xsl:call-template name="Test_Settings" />
				<xsl:call-template name="Card_Assessment" />
				<xsl:call-template name="Card_ResidualRemanence" />
				<xsl:call-template name="Card_Burden" />
				<xsl:call-template name="Card_Resistance_Combined" />
				<xsl:call-template name="Card_Ratio" />
				<xsl:call-template name="Card_Excitation" />

				<!-- End HTML body-->
			</body>

			<!-- End HTML -->
		</html>
	</xsl:template>


	<!-- Definition of the HTML header including the CSS styles -->
	<xsl:template name="html_head">

		<head>
			<style type="text/css" media="screen, print">

				* {
				font-family: Verdana, Helvetica, Arial;
				font-size: 8pt;
				}

				body {
				font-family: Verdana, Helvetica, Arial;
				font-size: 8pt;
				}

				h1, h2 {
				page-break-after: avoid;
				font-size: medium;

				padding-top: 0px;
				padding-right: 20px;
				padding-bottom: 0px;
				padding-left: 20px;

				margin-top: 30px;
				margin-right: 0px;
				margin-bottom: 10px;
				margin-left: 0px;
				}

				h1 {
				margin-top: 10px;
				}

				h2 {

				page-break-after: avoid;
				padding-left: 0px;
				font-size: small;
				display: block;

				background-color: #fafafa;
				}

				h3 {
				page-break-after: avoid;
				font-size: x-small;
				font-style: italic;
				font-weight: normal;
				}

				td {
				padding-top: 1px;
				padding-right: 5px;
				padding-bottom: 1px;
				padding-left: 5px;
				}

				td.empty {
				padding-top: 0px;
				padding-right: 0px;
				padding-bottom: 0px;
				padding-left: 0px;
				}

				tr.blank {
				height: 2em;
				border-style: none;
				}

				th {
				padding-top: 3px;
				padding-right: 5px;
				padding-bottom: 3px;
				padding-left: 5px;

				background-color: #efefef;
				<!--word-wrap:break-word;-->
				}



				table {
				padding-top: 0px;
				padding-right: 0px;
				padding-bottom: 0px;
				padding-left: 0px;

				margin-top: 0px;
				margin-right: 0px;
				margin-bottom: 0px;
				margin-left: 0px;
				}

				table, th, td {
				border-collapse: collapse;
				}

				thead {
				border-bottom: 5px;
				border-left: 5px;
				border-top: 5px;
				border-right: 5px;

				border-style: solid;
				}


				.valueTable{
				padding: 5px;

				border-style: solid;
				border-width: 1px;
				}

				.valueTable * td{
				border-top-style:solid;
				border-right-style:solid;
				border-bottom-style:solid;
				border-left-style:solid;
				border-width: 1px;
				}

				.breakText{
					word-break:break-all;
					white-space: normal;
				}

				.infoTable{
				margin-top: 0px;
				margin-right: 0px;
				margin-bottom: 0px;
				margin-left: 0px;

				border-style: none;
				border-width: 1px;
				}

				.infoTable * tr{
				border-top-style:solid;
				border-right-style:solid;
				border-bottom-style:solid;
				border-left-style:solid;
				border-width: 1px;
				}

				.tableDivider{
				font-weight: bold;
				padding-top: 20px;
				padding-bottom: 5px;


				border-bottom: 1px;
				border-left: 0px;
				border-top: 0px;
				border-right: 0px;
				border-style: solid;

				border-top-style:none;
				border-right-style:none;
				border-bottom-style:solid;
				border-left-style:none;
				}

				.tableDivider2 {
				font-weight: bold;

				padding-top: 5px;
				padding-bottom: 5px;

				background-color: #efefef;
				}

				.descriptor {
				font-weight: bold;

				padding-top: 1px;
				padding-right: 7px;
				padding-bottom: 1px;
				padding-left: 25px;

				white-space: nowrap;

				text-align: right;
				}

				.value {
				padding-top: 1px;
				padding-right: 35px;
				padding-bottom: 1px;
				padding-left: 7px;

				white-space: nowrap;
				}

				.decimalValue {
				padding-top: 1px;
				padding-right: 10px;
				padding-bottom: 1px;
				padding-left: 10px;

				white-space: nowrap;
				text-align: right;
				}

				.assessment {
				white-space: nowrap;
				text-align: center;
				}


				#generalData {
				background-color: #fafafa;

				border-bottom: 1px;
				border-left: 0px;
				border-top: 1px;
				border-right: 0px;

				border-top-style:solid;
				border-right-style:none;
				border-bottom-style:solid;
				border-left-style:none;

				margin-top: 10px;
				margin-right: 0px;
				margin-bottom: 10px;
				margin-left: 0px;

				padding-top: 10px;
				padding-right: 20px;
				padding-bottom: 10px;
				padding-left: 20px;
				}

				#objectData, #measurementData {
				background-color: #fafafa;

				border-bottom: 0px;
				border-left: 1px;
				border-top: 1px;
				border-right: 0px;

				border-style: solid;

				margin-top: 15px;
				margin-right: 15px;
				margin-bottom: 15px;
				margin-left: 15px;

				padding-top: 5px;
				padding-right: 5px;
				padding-bottom: 5px;
				padding-left: 5px;
				}

				#deviceInfoTable.* {
				border-style: none;

				padding-top: 2px;
				padding-right: 15px;
				padding-bottom: 2px;
				padding-left: 15px;
				}

				#styleSheetVersionInfo {
				text-align: right;
				float: right;
				}

				#styleSheetVersionInfo.* {
				font-size: 7pt;
				}

				.dataBlock{
				float: left;

				border-style: none;
				border-width: 1px;
				}

				.dataBlockEnd {
				float: clear;

				padding-top: 5px;
				padding-bottom: 15px;

				border-style: none;
				border-width: 3px;
				}

				.clsBorder {
				border-style: solid;
				}
			</style>
		</head>


	</xsl:template>


	<!--Processes all necessary information about the CTA device from Card general-->
	<xsl:template name="General_Device_Data">
		<!--Last used text ID for card general is 40 -->
		<h1 rid="CARD_GENERAL_000">Test Report</h1>

		<div id="generalData">
			<table class="infoTable">
				<tr>
					<td class="descriptor"  rid="CARD_GENERAL_005">Date/Time:</td>
					<td class="value">
						<xsl:value-of select="Tests/General/Time" />
					</td>
				</tr>

				<tr class="blank">
					<td/>
				</tr>

				<!--show the overall assessment-->
				<xsl:call-template name="Card_Ass_Total" />

				<tr class="blank">
					<td/>
				</tr>
			</table>

			<table class="infoTable">

				<!-- Location Settings -->
				<xsl:call-template name="Test_Location_Settings" />

				<!-- CT Object Settings -->
				<xsl:call-template name="Test_Object_Settings" />
				<!-- Print comment -->
				<xsl:call-template name="Test_Comment" />
				<!-- CT Object Settings -->
				<xsl:call-template name="Test_Equipment" />

			</table>
		</div>
	</xsl:template>

	<xsl:template name="Test_Settings">
		<!-- Test Settings: -->
		<!-- Last used text ID for card object is 54 -->
		<h2 rid="CARD_OBJECT_000" style="page-break-before: always;">Test Settings:</h2>

		<div id="generalData">
			<div class="dataBlockEnd">
				<table>
					<!--Check whether the values are limited by an low boundary at the CTA-->
					<!--Only significantly for IEC 60044-1 M CTs with 5A Isn-->
					<!--The value is device dependend and can be set only in the device settings. "0.00" means no limit is set.-->
					<xsl:if test="TestObject/Standard = '60044-1' and TestObject/Isn/Val = 5.0  and TestObject/MinimalPower/Val &gt; 0.0" >
						<tr>
							<td/>
							<td/>
							<xsl:call-template name="Card_Settings_Low_Burden_Limit" />
						</tr>
					</xsl:if>
					<!--Check whether burden values are allowed below 1VA at the CTA-->
					<!--The value is device dependend and can be set only in the device settings. "0.00" means no limit is set.-->
					<xsl:if test="TestObject/EnableLowBurden &gt; 0.0" >
						<tr>
							<td/>
							<td/>
							<xsl:call-template name="Card_Settings_Rated_Burden_Below_1VA" />
						</tr>
					</xsl:if>
					
					<tr>
						<xsl:call-template name="Card_Settings_Ipn" />
						<xsl:call-template name="Card_Settings_Nominal_Burden" />
					</tr>
					<tr>
						<xsl:call-template name="Card_Settings_Isn" />
						<xsl:call-template name="Card_Settings_Operating_Burden" />
					</tr>
					<tr>
						<xsl:call-template name="Card_Settings_Frequency" />
					</tr>

					<tr class="blank">
						<td/>
					</tr>

					<tr>
						<xsl:call-template name="Card_Settings_Standard" />
						<xsl:call-template name="Card_Settings_Core_Type" />
					</tr>

					<tr>
						<xsl:call-template name="Card_Settings_Class"/>
					</tr>
					<tr>
						<xsl:call-template name="Card_Settings_Rct" />
					</tr>

					<tr class="blank">
						<td/>
					</tr>


					<!--standard & class specific settings-->
					<xsl:choose>
						<xsl:when test="TestObject/Standard = '60044-1'">
							<xsl:choose>
								<xsl:when test="TestObject/CoreType = 'P'">
									<xsl:choose>

										<xsl:when test="TestObject/Class = 'PX'">
											<tr>
												<xsl:call-template name="Card_Settings_Kx" />
											</tr>
											<tr>
												<xsl:call-template name="Card_Settings_Ek" />
												<xsl:call-template name="Card_Settings_Ie" />
											</tr>
											<tr>
												<xsl:call-template name="Card_Settings_E1" />
												<xsl:call-template name="Card_Settings_Ie1" />
											</tr>
										</xsl:when>

										<xsl:when test="contains(TestObject/Class,'PR')">
											<tr>
												<xsl:call-template name="Card_Settings_ALF" />
												<xsl:call-template name="Card_Settings_Ts" />
											</tr>
										</xsl:when>

										<!--normal P classes-->
										<xsl:otherwise>
											<tr>
												<xsl:call-template name="Card_Settings_ALF" />
											</tr>
										</xsl:otherwise>

									</xsl:choose>
								</xsl:when>

								<xsl:when test="TestObject/CoreType = 'M'">
									<tr>
										<xsl:call-template name="Card_Settings_FS" />
										<xsl:call-template name="Card_Settings_Ext" />
									</tr>
									<tr>
										<td/>
										<td/>
										<xsl:call-template name="Card_Settings_Ext_VA" />
									</tr>
								</xsl:when>

								<xsl:otherwise>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>

						<xsl:when test="TestObject/Standard = '60044-6'">
							<xsl:choose>

								<xsl:when test="TestObject/Class = 'TPS'">
									<tr>
										<xsl:call-template name="Card_Settings_K" />
										<xsl:call-template name="Card_Settings_Kssc" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Tp" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Val" />
										<xsl:call-template name="Card_Settings_Ial" />
									</tr>
								</xsl:when>

								<xsl:when test="TestObject/Class = 'TPX'">
									<tr>
										<xsl:call-template name="Card_Settings_Ktd" />
										<xsl:call-template name="Card_Settings_Kssc" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Tp" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Duty_Cycle" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_t1" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_tal1" />
									</tr>
									<xsl:if test="TestObject/Sequence != 'C-t1-O'">
										<tr>
											<xsl:call-template name="Card_Settings_tfr" />
											<xsl:call-template name="Card_Settings_tal2" />
										</tr>
									</xsl:if>
								</xsl:when>

								<xsl:when test="TestObject/Class = 'TPY'">
									<tr>
										<xsl:call-template name="Card_Settings_Ktd" />
										<xsl:call-template name="Card_Settings_Kssc" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Tp" />
										<xsl:call-template name="Card_Settings_Ts" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Duty_Cycle" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_t1" />
										<xsl:call-template name="Card_Settings_tal1" />
									</tr>
									<xsl:if test="TestObject/Sequence != 'C-t1-O'">
										<tr>
											<xsl:call-template name="Card_Settings_tfr" />
											<xsl:call-template name="Card_Settings_tal2" />
										</tr>
									</xsl:if>
								</xsl:when>

								<xsl:when test="TestObject/Class = 'TPZ'">
									<tr>
										<xsl:call-template name="Card_Settings_Ktd" />
										<xsl:call-template name="Card_Settings_Kssc" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Tp" />
										<xsl:call-template name="Card_Settings_Ts" />
									</tr>
								</xsl:when>

								<xsl:otherwise>
									<tr>
										<td class="descriptor">unknown class</td>
										<td class="value">
											no handling for class <xsl:value-of select="TestObject/Class" />
										</td>
									</tr>
								</xsl:otherwise>

							</xsl:choose>
						</xsl:when>

						<xsl:when test="starts-with(TestObject/Standard,'ANSI')">

							<!-- ANSI standards (IEEE 57.13) -->
							<xsl:choose>
								<!--Protection classes-->
								<xsl:when test="TestObject/Class = 'C' or TestObject/Class = 'K'">
									<tr>
										<xsl:call-template name="Card_Settings_Vb" />
									</tr>
								</xsl:when>

								<xsl:when test="TestObject/Class = 'X'">
									<tr>
										<xsl:call-template name="Card_Settings_Re20xIsn" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Vk" />
										<xsl:call-template name="Card_Settings_Ik" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Vk1" />
										<xsl:call-template name="Card_Settings_Ik1" />
									</tr>
								</xsl:when>

								<xsl:when test="TestObject/Class = 'T'">
									<tr>
										<xsl:call-template name="Card_Settings_Vb" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Vk" />
										<xsl:call-template name="Card_Settings_Ik" />
									</tr>
									<tr>
										<xsl:call-template name="Card_Settings_Vk1" />
										<xsl:call-template name="Card_Settings_Ik1" />
									</tr>
								</xsl:when>

								<!--Metering classes-->
								<xsl:when test="TestObject/Class = '0.15' or TestObject/Class = '0.15s' or TestObject/Class = '0.3' or TestObject/Class = '0.6' or TestObject/Class = '1.2' or TestObject/Class = '2.4' or TestObject/Class = '4.8'">
									<!--all metering classes-->
									<tr>
										<xsl:call-template name="Card_Settings_RF" />
									</tr>
								</xsl:when>

								<xsl:otherwise>
									<tr>
										<td class="descriptor">unknown class</td>
										<td class="value">
											no handling for class <xsl:value-of select="TestObject/Class" />
										</td>
									</tr>
								</xsl:otherwise>
							</xsl:choose>

						</xsl:when>

						<xsl:when test="TestObject/Standard = '61869-2'">
							<xsl:choose>
								<xsl:when test="TestObject/CoreType = 'P'">
									<xsl:choose>
										<!--simple protection classes-->
										<xsl:when test="not(contains(TestObject/Class,'TP')) and not(contains(TestObject/Class,'PR')) and not(contains(TestObject/Class,'PX'))">
											<tr>
												<xsl:call-template name="Card_Settings_ALF" />
											</tr>
										</xsl:when>

										<!--protection classes PR-->
										<xsl:when test="contains(TestObject/Class,'PR')">
											<tr>
												<xsl:call-template name="Card_Settings_ALF" />
												<xsl:call-template name="Card_Settings_Ts" />
											</tr>
										</xsl:when>

										<!--protection classes PX and PXR-->
										<xsl:when test="TestObject/Class = 'PXR'">
											<tr>
												<xsl:call-template name="Card_Settings_Kx" />
												<xsl:call-template name="Card_Settings_Ts" />
											</tr>
											<tr>
												<xsl:call-template name="Card_Settings_Ek" />
												<xsl:call-template name="Card_Settings_Ie" />
											</tr>
											<tr>
												<xsl:call-template name="Card_Settings_E1" />
												<xsl:call-template name="Card_Settings_Ie1" />
											</tr>
										</xsl:when>
										<xsl:when test="TestObject/Class = 'PX'">
											<tr>
												<xsl:call-template name="Card_Settings_Kx" />
											</tr>
											<tr>
												<xsl:call-template name="Card_Settings_Ek" />
												<xsl:call-template name="Card_Settings_Ie" />
											</tr>
											<tr>
												<xsl:call-template name="Card_Settings_E1" />
												<xsl:call-template name="Card_Settings_Ie1" />
											</tr>
										</xsl:when>


										<!--transient classes-->
										<xsl:when test="TestObject/Class = 'TPX'">
											<tr>
												<xsl:call-template name="Card_Settings_SpecMethod" />
											</tr>
											<xsl:choose>
												<xsl:when test="TestObject/TPSpecMtd = 'Standard'">
													<tr>
														<xsl:call-template name="Card_Settings_Duty_Cycle" />
														<xsl:call-template name="Card_Settings_Kssc" />
													</tr>
													<tr>
														<xsl:call-template name="Card_Settings_Tp" />
														<xsl:call-template name="Card_Settings_tal1" />
													</tr>
													<xsl:if test="TestObject/Sequence != 'C-t1-O'">
														<tr>
															<xsl:call-template name="Card_Settings_t1" />
															<xsl:call-template name="Card_Settings_tal2" />
														</tr>
														<tr>
															<xsl:call-template name="Card_Settings_tfr" />
														</tr>
													</xsl:if>
												</xsl:when>
												<xsl:when test="TestObject/TPSpecMtd = 'Altern'">
													<tr>
														<xsl:call-template name="Card_Settings_Ktd" />
														<xsl:call-template name="Card_Settings_Kssc" />
													</tr>
												</xsl:when>
												<xsl:otherwise>
													<!--TP specification method not defined -> no handling possible-->
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>

										<xsl:when test="TestObject/Class = 'TPY'">
											<tr>
												<xsl:call-template name="Card_Settings_SpecMethod" />
											</tr>
											<xsl:choose>
												<xsl:when test="TestObject/TPSpecMtd = 'Standard'">
													<tr>
														<xsl:call-template name="Card_Settings_Duty_Cycle" />
														<xsl:call-template name="Card_Settings_Kssc" />
													</tr>
													<tr>
														<xsl:call-template name="Card_Settings_Tp" />

													</tr>
													<tr>
														<xsl:call-template name="Card_Settings_Ts" />
														<xsl:call-template name="Card_Settings_tal1" />
													</tr>
													<xsl:if test="TestObject/Sequence != 'C-t1-O'">
														<tr>
															<xsl:call-template name="Card_Settings_t1" />
															<xsl:call-template name="Card_Settings_tal2" />
														</tr>
														<tr>
															<xsl:call-template name="Card_Settings_tfr" />
														</tr>
													</xsl:if>
												</xsl:when>
												<xsl:when test="TestObject/TPSpecMtd = 'Altern'">
													<tr>
														<xsl:call-template name="Card_Settings_Ktd" />
														<xsl:call-template name="Card_Settings_Kssc" />
													</tr>
													<tr>
														<xsl:call-template name="Card_Settings_Ts" />
													</tr>
												</xsl:when>
												<xsl:otherwise>
													<!--TP specification method not defined -> no handling possible-->
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>

										<xsl:when test="TestObject/Class = 'TPZ'">
											<tr>
												<xsl:call-template name="Card_Settings_SpecMethod" />
											</tr>
											<xsl:choose>
												<xsl:when test="TestObject/TPSpecMtd = 'Standard'">
													<tr>
														<xsl:call-template name="Card_Settings_Duty_Cycle" />
														<xsl:call-template name="Card_Settings_Kssc" />
													</tr>
													<tr>
														<xsl:call-template name="Card_Settings_Tp" />
														<xsl:call-template name="Card_Settings_tal1" />
													</tr>
													<xsl:if test="TestObject/Sequence != 'C-t1-O'">
														<tr>
															<xsl:call-template name="Card_Settings_t1" />
															<xsl:call-template name="Card_Settings_tal2" />
														</tr>
														<tr>
															<xsl:call-template name="Card_Settings_tfr" />
														</tr>
													</xsl:if>
												</xsl:when>
												<xsl:when test="TestObject/TPSpecMtd = 'Altern'">
													<tr>
														<xsl:call-template name="Card_Settings_Ktd" />
														<xsl:call-template name="Card_Settings_Kssc" />
													</tr>
												</xsl:when>
												<xsl:otherwise>
													<!--TP specification method not defined -> no handling possible-->
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>

										<xsl:otherwise>
											<tr>
												<td class="descriptor">unkown class</td>
												<td class="value">
													no handling for class <xsl:value-of select="TestObject/Class" />
												</td>
											</tr>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:when test="TestObject/CoreType = 'M'">
									<tr>
										<xsl:call-template name="Card_Settings_FS" />
										<xsl:call-template name="Card_Settings_Ext" />
									</tr>
									<tr>
										<td/>
										<td/>
										<xsl:call-template name="Card_Settings_Ext_VA" />
									</tr>

								</xsl:when>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<tr>
								<td class="descriptor">Unknown standard</td>
								<td class="value">
											no handling for class <xsl:value-of select="TestObject/Class" />(<xsl:value-of select="TestObject/Standard" />)
								</td>
							</tr>
						</xsl:otherwise>
					</xsl:choose>

				</table>

				<!-- additional special values -->
				<table name="special values">
					<tr class="blank">
						<td/>
					</tr>
					<tr>
						<td class="descriptor" rid="CARD_ASS_091">Multiplying Factor for Ratio Assessment:</td>
						<td class="value" colspan="3">
							<xsl:value-of select="TestObject/ClassMultiplier/Displ" />
						</td>
					</tr>
					<tr>
						<td class="descriptor" rid="CARD_RATIO_101">Delta compensation:</td>
						<td class="value">
							<xsl:choose>
								<xsl:when test="Tests/Cards/Ratio/Settings/DeltaCompensation = '0'">
									<IDTag rid="CARD_RATIO_102">Ratio 1</IDTag>
								</xsl:when>
								<xsl:when test="Tests/Cards/Ratio/Settings/DeltaCompensation = '1'">
									<IDTag rid="CARD_RATIO_103">Ratio 2/3</IDTag>
								</xsl:when>
								<xsl:when test="Tests/Cards/Ratio/Settings/DeltaCompensation = '2'">
									<IDTag rid="CARD_RATIO_104">Ratio 1/3</IDTag>
								</xsl:when>
							</xsl:choose>
						</td>
					</tr>
				</table>
			</div>
			<div name="settings legend">
				<div>
					<sup>? </sup>
					<IDTag rid="CARD_OBJECT_063">Value is automatically detected by CT Analyzer's guesser function.</IDTag>
				</div>
				<div>
					<sup>* </sup>
					<IDTag rid="CARD_OBJECT_069">Auto-detection may prevent assessment. Explicit setting might be mandatory for automatic assessment.</IDTag>
				</div>
			</div>
		</div>
	</xsl:template>

	<xsl:template name="Test_Location_Settings">
		<!-- Location Settings -->
		<xsl:choose>
			<!--compatibility for CTA report older then version 3.0-->
			<xsl:when test="Version &lt; '3'">
				<tr>
					<td class="descriptor" rid="CARD_OBJECT_001">Identification:</td>
					<td class="value">
						<xsl:value-of select="TestObject/Info/Identity" />
					</td>
				</tr>
			</xsl:when>
			<!--compatibility for CTA report version 3.0 or newer-->
			<xsl:otherwise>
				<tr>
					<td class="tableDivider2"  colspan="4" rid="CARD_OBJECT_060">Location</td>
				</tr>
				<tr>
					<td class="descriptor" rid="CARD_OBJECT_047">Company:</td>
					<td class="value">
						<xsl:value-of select="TestObject/Info/Company" />
					</td>

					<td class="descriptor" rid="CARD_OBJECT_048">Country:</td>
					<td class="value">
						<xsl:value-of select="TestObject/Info/Country" />
					</td>
				</tr>
				<tr>
					<td class="descriptor" rid="CARD_OBJECT_049">Station:</td>
					<td class="value">
						<xsl:value-of select="TestObject/Info/Station" />
					</td>
					<td class="descriptor" rid="CARD_OBJECT_050">Feeder:</td>
					<td class="value">
						<xsl:value-of select="TestObject/Info/Feeder" />
					</td>
				</tr>
				<tr>
					<td class="descriptor" rid="CARD_OBJECT_051">Phase:</td>
					<td class="value">
						<xsl:value-of select="TestObject/Info/Phase" />
					</td>

					<td class="descriptor" rid="CARD_OBJECT_052">IEC-ID:</td>
					<td class="value">
						<xsl:value-of select="TestObject/Info/IECID" />
					</td>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="Test_Object_Settings">
		<!-- CT Object Settings -->
		<tr class="blank">
			<td/>
		</tr>
		<tr>
			<td class="tableDivider2" colspan="4" rid="CARD_OBJECT_062">CT Nameplate</td>
		</tr>
		<tr>
			<td class="descriptor" rid="CARD_OBJECT_002">Manufacturer:</td>
			<td class="value">
				<xsl:value-of select="TestObject/Info/Manufacturer" />
			</td>

			<td class="descriptor" rid="CARD_OBJECT_053">Tap:</td>
			<td class="value">
				<xsl:value-of select="TestObject/Info/Tap" />
			</td>
		</tr>
		<tr>
			<td class="descriptor" rid="CARD_OBJECT_003">Type:</td>
			<td class="value">
				<xsl:value-of select="TestObject/Info/Type" />
			</td>

			<td class="descriptor" rid="CARD_OBJECT_005">Core Number:</td>
			<td class="value">
				<xsl:value-of select="TestObject/Info/CoreNumber" />
			</td>
		</tr>
		<tr>
			<td class="descriptor" rid="CARD_OBJECT_004">Serial Number:</td>
			<td class="value">
				<xsl:value-of select="TestObject/Info/SerialNumber" />
			</td>

			<td class="descriptor" rid="CARD_OBJECT_054">Optional 1:</td>
			<td class="value">
				<xsl:value-of select="TestObject/Info/Option1" />
			</td>
		</tr>
		<tr class="blank">
			<td />
		</tr>
		<tr>
			<td class="descriptor" rid="CARD_RATIO_000">Ratio:</td>
			<td class="value">
				<xsl:value-of select="$ctRatio" />
			</td>

			<td class="descriptor" rid="CARD_OBJECT_009">Core Type:</td>
			<td class="value">
				<xsl:choose>
					<xsl:when test="TestObject/CoreType = 'P'">
						<IDTag rid="CARD_OBJECT_036">Protection CT</IDTag>
					</xsl:when>
					<xsl:when test="TestObject/CoreType = 'M'">
						<IDTag rid="CARD_OBJECT_037">Metering CT</IDTag>
					</xsl:when>
					<xsl:when test="TestObject/CoreType = '?'">
						<IDTag rid="CARD_OBJECT_038">?</IDTag>
					</xsl:when>
				</xsl:choose>
			</td>
		</tr>
		<tr>
			<td class="descriptor" rid="CARD_OBJECT_012">Frequency:</td>
			<td class="value">
				<xsl:value-of select="$frequency" />
			</td>
			<td class="descriptor" rid="CARD_OBJECT_010">Class:</td>
			<td class="value">
				<xsl:value-of select="$class" />
				<xsl:if test="TestObject/ClassAssessAt = 1">
					<!--only for C57.13 metering-->
					 @ <xsl:value-of select="$nominalPower"/>
				</xsl:if>
				- <xsl:value-of select="TestObject/ClassString[. != '?']" /> (<xsl:value-of select="$standardName" />)
			</td>
		</tr>
		<tr>
			<td class="descriptor" rid="CARD_OBJECT_013">Nominal Burden:</td>
			<td class="value">
				<xsl:value-of select="$nominalPower" />
			</td>
			<td class="descriptor" rid="CARD_OBJECT_014">Operating Burden:</td>
			<td class="value">
				<xsl:value-of select="$nominalBurden" />
			</td>
		</tr>

	</xsl:template>

	<xsl:template name="Test_Equipment">
		<!-- CT Object Settings -->
		<tr class="blank">
			<td/>
		</tr>
		<tr>
			<td class="tableDivider2" colspan="4" rid="CARD_OBJECT_061">Equipment</td>
		</tr>
		<tr>
			<td class="descriptor" rid="CARD_GENERAL_001">Test Device:</td>
			<td class="value">
				<xsl:value-of select="Hardware/Type" />
			</td>

			<td class="descriptor"  rid="CARD_GENERAL_003">Software Version:</td>
			<td class="value">
				<xsl:value-of select="Hardware/SoftwareVersion" />
			</td>
		</tr>
		<tr>
			<td class="descriptor"  rid="CARD_GENERAL_002">Serial Number:</td>
			<td class="value">
				<xsl:value-of select="Hardware/SerialNumber" />
			</td>

			<td class="descriptor"  rid="CARD_GENERAL_004">Hardware Version:</td>
			<td class="value">
				<xsl:value-of select="Hardware/HardwareVersion" />
			</td>
		</tr>
		<tr class="blank">
			<td />
		</tr>

		<!--Switch box accessory-->
		<xsl:if test="Hardware/SwitchBox/SerialNumber != ''">
			<tr>
				<td class="descriptor" rid="CARD_GENERAL_001">Test Device:</td>
				<td class="value">
					<xsl:value-of select="Hardware/SwitchBox/Type" />
				</td>

				<td class="descriptor"  rid="CARD_GENERAL_003">Software Version:</td>
				<td class="value">
					<xsl:value-of select="substring(Hardware/SwitchBox/Version,0,5)" />
				</td>
			</tr>
			<tr>
				<td class="descriptor"  rid="CARD_GENERAL_002">Serial Number:</td>
				<td class="value">
					<xsl:value-of select="Hardware/SwitchBox/SerialNumber" />
				</td>

				<td class="descriptor"  rid="CARD_GENERAL_004">Hardware Version:</td>
				<td class="value">
					<xsl:value-of select="substring(Hardware/SwitchBox/Version,6)" />
				</td>
			</tr>
			<tr class="blank">
				<td />
			</tr>
		</xsl:if>

		<!-- print the HW status only in case of error-->
		<xsl:if test="not(Tests/General/Status/Hardware/Status = 1)">
			<tr>
				<td class="descriptor"  rid="CARD_GENERAL_007">Status Info:</td>
				<td class="value" colspan="3">
					<xsl:call-template name="Resolve_Status_message">
						<xsl:with-param name="status_value" select="Tests/General/Status/Hardware/Status" />
					</xsl:call-template>
				</td>
			</tr>

			<xsl:if test="Tests/General/Status/Hardware/Status = -1">
				<tr>
					<td class="descriptor" >
						<xsl:choose>
							<xsl:when test="Tests/General/Status/Hardware/Priority = 1">
								<IDTag rid="CARD_GENERAL_011">Error:</IDTag>
							</xsl:when>
							<xsl:otherwise>
								<IDTag rid="CARD_GENERAL_012">Warning:</IDTag>
							</xsl:otherwise>
						</xsl:choose>
					</td>
					<td class="value">
						<xsl:value-of select="Tests/General/Status/Hardware/ErrNum" />.<xsl:value-of select="Tests/General/Status/Hardware/ErrLoc" />
					</td>
				</tr>
			</xsl:if>

		</xsl:if>
	</xsl:template>

	<xsl:template name="Test_Comment">
		<!--Card Burden -->
		<!--Last used text ID for card burden is 18-->
		<xsl:param name="CommentCard" select="Tests/Cards/Comment" />

		<xsl:if test="$CommentCard/Settings/Comment/. !=''">
			<tr class="blank">
				<td/>
			</tr>
			<tr>
				<td class="tableDivider2" colspan="4" rid="CARD_Comment_01">Comment</td>
			</tr>
			<tr>
				<td/>
				<td class="value breakText" colspan="3">
					<xsl:value-of select="$CommentCard/Settings/Comment/." />
				</td>
			</tr>
		</xsl:if>
	</xsl:template>

	<xsl:template name="Card_Assessment">


		<!-- Assessments: -->
		<!-- Last used text ID for card assessment is 129 -->
		<xsl:if test="Tests/Cards/Assessment/Status/Card/Select = '1'">
			<!--Check double RID-->
			<h2 rid="CARD_ASS_000">Assessments:</h2>
			<div class="dataBlockEnd">
				<table class="valueTable">
					<thead>
						<tr>
							<th align="left" rid="CARD_ASS_001">Parameter</th>
							<th align="center" rid="CARD_ASS_002">Auto</th>
							<th align="center" rid="CARD_ASS_003">Manual</th>
						</tr>
					</thead>
					<tbody>
						<!-- Class , will be done for every class-->
						<xsl:call-template name="Card_Ass_Class" />

						<xsl:choose>
							<xsl:when test="TestObject/Standard = '60044-1'">
								<xsl:choose>
									<xsl:when test="TestObject/CoreType = 'M'">

										<xsl:call-template name="Card_Ass_Ratio_Error" />
										<xsl:if test="TestObject/Class != '3' and TestObject/Class != '5'">
											<!-- Delta Phi -->
											<xsl:call-template name="Card_Ass_Delta_Phi" />
										</xsl:if>
										<xsl:call-template name="Card_Ass_FS" />
										<xsl:call-template name="Card_Ass_FSi" />

									</xsl:when>
									<xsl:when test="TestObject/CoreType = 'P'">
										<xsl:choose>
											<xsl:when test="TestObject/Class = 'PX'">
												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Turns_Error" />
												<xsl:call-template name="Card_Ass_Kx" />
												<xsl:call-template name="Card_Ass_Ek" />
												<xsl:call-template name="Card_Ass_Ie" />
												<xsl:call-template name="Card_Ass_Ie1" />

											</xsl:when>
											<xsl:when test="TestObject/Class = '10P'">
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />

											</xsl:when>

											<xsl:when test="TestObject/Class = '10PR'">
												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />
												<xsl:call-template name="Card_Ass_Kr" />
												<xsl:call-template name="Card_Ass_Ts" />

											</xsl:when>

											<xsl:when test="contains(TestObject/Class,'PR') and TestObject/Class != '10PR'">
												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Delta_Phi" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />
												<xsl:call-template name="Card_Ass_Kr" />
												<xsl:call-template name="Card_Ass_Ts" />

											</xsl:when>

											<!--normal P classes-->
											<xsl:otherwise>

												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Delta_Phi" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />

											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>

									<xsl:when test="TestObject/CoreType = '?'">

										<xsl:call-template name="Card_Ass_Ratio_Error" />

									</xsl:when>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="TestObject/Standard = '60044-6'">
								<xsl:call-template name="Card_Ass_Rct" />

								<xsl:choose>
									<xsl:when test="TestObject/Class = 'TPS'">

										<xsl:call-template name="Card_Ass_Turns_Error" />
										<xsl:call-template name="Card_Ass_K_x_Kssc" />
										<xsl:call-template name="Card_Ass_U_Al" />
										<xsl:call-template name="Card_Ass_I_Al" />

									</xsl:when>
									<xsl:when test="TestObject/Class = 'TPX'">

										<xsl:call-template name="Card_Ass_Ratio_Error" />
										<xsl:call-template name="Card_Ass_Delta_Phi" />
										<xsl:call-template name="Card_Ass_Peak_Error" />
										<xsl:call-template name="Card_Ass_Ktd_x_Kssc" />

									</xsl:when>
									<xsl:when test="TestObject/Class = 'TPY'">

										<xsl:call-template name="Card_Ass_Ratio_Error" />
										<xsl:call-template name="Card_Ass_Delta_Phi" />
										<xsl:call-template name="Card_Ass_Peak_Error" />
										<xsl:call-template name="Card_Ass_Ktd_x_Kssc" />
										<xsl:call-template name="Card_Ass_Ts" />
										<xsl:call-template name="Card_Ass_Kr" />

									</xsl:when>
									<xsl:when test="TestObject/Class = 'TPZ'">

										<xsl:call-template name="Card_Ass_Ratio_Error" />
										<xsl:call-template name="Card_Ass_Delta_Phi" />
										<xsl:call-template name="Card_Ass_Peak_Error_AC" />
										<xsl:call-template name="Card_Ass_Ktd_x_Kssc" />
										<xsl:call-template name="Card_Ass_Ts" />

									</xsl:when>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="TestObject/Standard = '61869-2'">
								<xsl:choose>
									<xsl:when test="TestObject/CoreType = 'M'">

										<xsl:call-template name="Card_Ass_Ratio_Error" />
										<xsl:if test="TestObject/Class != '3' and TestObject/Class != '5'">
											<!-- Delta Phi -->
											<xsl:call-template name="Card_Ass_Delta_Phi" />
										</xsl:if>
										<xsl:call-template name="Card_Ass_FS" />
										<xsl:call-template name="Card_Ass_FSi" />

									</xsl:when>
									<xsl:when test="TestObject/CoreType = 'P'">
										<xsl:choose>
											<xsl:when test="TestObject/Class = 'PX'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Turns_Error" />
												<xsl:call-template name="Card_Ass_Kx" />
												<xsl:call-template name="Card_Ass_Ek" />
												<xsl:call-template name="Card_Ass_Ie" />
												<xsl:call-template name="Card_Ass_Ie1" />

											</xsl:when>
											<xsl:when test="TestObject/Class = 'PXR'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Turns_Error" />
												<xsl:call-template name="Card_Ass_Kr" />
												<xsl:call-template name="Card_Ass_Kx" />
												<xsl:call-template name="Card_Ass_Ek" />
												<xsl:call-template name="Card_Ass_Ie" />
												<xsl:call-template name="Card_Ass_Ie1" />

											</xsl:when>
											<xsl:when test="TestObject/Class = '10P'">

												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />

											</xsl:when>
											<xsl:when test="TestObject/Class = '10PR'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />
												<xsl:call-template name="Card_Ass_Kr" />
												<xsl:call-template name="Card_Ass_Ts" />

											</xsl:when>
											<xsl:when test="contains(TestObject/Class,'PR') and TestObject/Class != '10PR'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Delta_Phi" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />
												<xsl:call-template name="Card_Ass_Kr" />
												<xsl:call-template name="Card_Ass_Ts" />

											</xsl:when>

											<!--transient classes-->
											<xsl:when test="TestObject/Class = 'TPX'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Delta_Phi" />
												<xsl:call-template name="Card_Ass_Peak_Error" />
												<xsl:call-template name="Card_Ass_Ktd_x_Kssc" />

											</xsl:when>
											<xsl:when test="TestObject/Class = 'TPY'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Delta_Phi" />
												<xsl:call-template name="Card_Ass_Peak_Error" />
												<xsl:call-template name="Card_Ass_Ktd_x_Kssc" />
												<xsl:call-template name="Card_Ass_Ts" />
												<xsl:call-template name="Card_Ass_Kr" />

											</xsl:when>
											<xsl:when test="TestObject/Class = 'TPZ'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Delta_Phi" />
												<xsl:call-template name="Card_Ass_Peak_Error_AC" />
												<xsl:call-template name="Card_Ass_Ktd_x_Kssc" />
												<xsl:call-template name="Card_Ass_Ts" />

											</xsl:when>

											<!--normal P classes-->
											<xsl:otherwise>

												<xsl:call-template name="Card_Ass_Ratio_Error" />
												<xsl:call-template name="Card_Ass_Delta_Phi" />
												<xsl:call-template name="Card_Ass_Composite_Error" />
												<xsl:call-template name="Card_Ass_ALF" />
												<xsl:call-template name="Card_Ass_ALFi" />

											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="TestObject/CoreType = '?'">

										<xsl:call-template name="Card_Ass_Ratio_Error" />

									</xsl:when>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$isIeeeStandard">
								<xsl:choose>
									<xsl:when test="TestObject/CoreType = 'M'">

										<xsl:call-template name="Card_Ass_Delta_Phi" />
										<xsl:call-template name="Card_Ass_RCF" />

									</xsl:when>
									<xsl:when test="TestObject/CoreType = 'P'">

										<xsl:call-template name="Card_Ass_Re_Isn" />
										<xsl:call-template name="Card_Ass_Re_20_Isn" />

										<!--C57.13 P classes-->
										<xsl:choose>
											<xsl:when test="TestObject/Class = 'C'">	

												<xsl:call-template name="Card_Ass_Vb" />

											</xsl:when>
											<xsl:when test="TestObject/Class = 'T'">

												<xsl:call-template name="Card_Ass_Vb" />
												<xsl:call-template name="Card_Ass_Vk-Ik" />
												<xsl:call-template name="Card_Ass_Vk1-Ik1" />

											</xsl:when>
											<xsl:when test="TestObject/Class = 'X'">

												<xsl:call-template name="Card_Ass_Rct" />
												<xsl:call-template name="Card_Ass_Vk-Ik" />
												<xsl:call-template name="Card_Ass_Vk1-Ik1" />

											</xsl:when>
											<xsl:when test="TestObject/Class = 'K'">

												<xsl:call-template name="Card_Ass_Vb" />
												<xsl:call-template name="Card_Ass_U_knee" />

											</xsl:when>
										</xsl:choose>

									</xsl:when>

									<xsl:when test="TestObject/CoreType = '?'">

										<xsl:call-template name="Card_Ass_Ts" />
										<xsl:call-template name="Card_Ass_Kr" />

									</xsl:when>
								</xsl:choose>
							</xsl:when>
						</xsl:choose>

						<!-- Burden -->
						<xsl:if test="Tests/Cards/Burden/Status/Card/Select = '1'">
							<xsl:call-template name="Card_Ass_Burden" />
						</xsl:if>
					</tbody>
				</table>
			</div>
		</xsl:if>
	</xsl:template>


	<xsl:template name="Card_ResidualRemanence">
		<!--Card Primary Resistance -->
		<xsl:param name="ResRemaCard" select="Tests/Cards/ResidualRemanence" />

		<xsl:if test="$ResRemaCard/Status/Card/Select = '1'">
			<h2 style="page-break-before: always" rid="CARD_RES_REMANENCE_000">Residual Magnetism:</h2>

			<!--Show status info-->
			<table>
				<!-- print only in case of error -->
				<xsl:call-template name="General_Hardware_Status">
					<xsl:with-param name="valuePath" select="$ResRemaCard/Status/Hardware" />
				</xsl:call-template>
			</table>

			<div class="dataBlockEnd">
				<table>
					<tr>
						<td class="tableDivider" rid="CARD_RES_REMANENCE_003" colspan="4">Results:</td>
					</tr>

					<tr>
						<td class="descriptor" rid="CARD_RES_REMANENCE_004">Residual Flux:</td>
						<td class="decimalValue">
							<xsl:value-of select="$ResRemaCard/Measurements/Flux/Displ" />
						</td>

						<td class="descriptor" rid="CARD_RES_REMANENCE_005">Residual Magnetism:</td>
						<td class="decimalValue">
							<xsl:value-of select="$ResRemaCard/Measurements/Percent/Displ" />
						</td>
					</tr>
					<tr>
						<td/>
						<td/>
						<td class="descriptor" rid="CARD_RES_REMANENCE_006">Remanence Factor (Kr):</td>
						<td class="decimalValue">
							<xsl:value-of select="Tests/Cards/Excitation/Measurements/PowerRelated/Kr/Displ" />
						</td>
					</tr>
				</table>
			</div>
		</xsl:if>
	</xsl:template>

	<xsl:template name="Card_Burden">
		<!--Card Burden -->
		<!--Last used text ID for card burden is 18-->
		<xsl:param name="BurdenCard" select="Tests/Cards/Burden" />

		<xsl:if test="$BurdenCard/Status/Card/Select = '1'">
			<h2 rid="CARD_BURDEN_000">Burden:</h2>

			<!--Show status info-->
			<table>
				<!-- print only in case of error -->
				<xsl:call-template name="General_Hardware_Status">
					<xsl:with-param name="valuePath" select="$BurdenCard/Status/Hardware" />
				</xsl:call-template>
				<tr>
					<td class="descriptor" rid="CARD_BURDEN_002">Overload:</td>
					<xsl:choose>
						<xsl:when test="$BurdenCard/Measurements/Overload = 0">
							<td class="value" rid="CARD_BURDEN_003">no</td>
						</xsl:when>
						<xsl:when test="$BurdenCard/Measurements/Overload = 1">
							<td class="value" rid="CARD_BURDEN_004">yes</td>
						</xsl:when>
					</xsl:choose>
				</tr>
			</table>


			<xsl:if test="$BurdenCard/Status/Hardware/Status = '1'">
				<div class="dataBlockEnd">
					<table>
						<tr>
							<td class="descriptor" rid="CARD_BURDEN_005">Frequency:</td>
							<td class="value">
								<xsl:value-of select="TestObject/Frequency/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_BURDEN_006">I-test:</td>
							<td class="value">
								<xsl:value-of select="$BurdenCard/Settings/Itest/Displ" />
							</td>
						</tr>
					</table>

					<table>
						<tr>
							<th align="left" rid="CARD_BURDEN_007">Results:</th>
						</tr>
					</table>
					<table>
						<tr>
							<th align="left" rid="CARD_BURDEN_008">I-meas.:</th>
							<td>
								<xsl:value-of select="$BurdenCard/Measurements/Imeas/Abs/Displ" />
							</td>
							<td>
								<xsl:value-of select="$BurdenCard/Measurements/Imeas/Phase/Displ" />
							</td>
						</tr>
						<tr>
							<th align="left" rid="CARD_BURDEN_009">V-meas.:</th>
							<td>
								<xsl:value-of select="$BurdenCard/Measurements/Vmeas/Abs/Displ" />
							</td>
							<td>
								<xsl:value-of select="$BurdenCard/Measurements/Vmeas/Phase/Displ" />
							</td>
						</tr>
						<tr>
							<th align="left" rid="CARD_BURDEN_010">Burden:</th>
							<td>
								<xsl:value-of select="$BurdenCard/Measurements/Burden/Power/Displ" />
							</td>
							<td>
								<IDTag rid="CARD_BURDEN_011">&#160;<span>cos &#966;:</span>&#160;</IDTag>
								<xsl:text disable-output-escaping="yes"/>
								<xsl:value-of select="$BurdenCard/Measurements/Burden/CosPhi/Displ" />
							</td>
						</tr>
						<tr>
							<th align="left" rid="CARD_BURDEN_012">Z:</th>
							<td>
								<xsl:value-of select="$BurdenCard/Measurements/Burden/Impedance/Displ" />
							</td>
						</tr>
					</table>
				</div>

			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template name="Card_Resistance_Combined">

		<xsl:param name="ResistanceCard" select="Tests/Cards/Resistance" />
		<xsl:param name="PrimaryResistanceCard" select="Tests/Cards/PrimaryResistance" />

		<xsl:param name="secResistanceMeas" select="Tests/Cards/Resistance/Measurements/Rmeas/Displ" />
		<xsl:param name="secResistanceRef" select="Tests/Cards/Resistance/Measurements/Rref/Displ" />
		<xsl:param name="secTemperatureMeas" select="Tests/Cards/Resistance/Settings/Tmeas/Displ" />
		<xsl:param name="secTemperatureRef" select="Tests/Cards/Resistance/Settings/Tref/Displ" />
		<xsl:param name="secVoltage" select="Tests/Cards/Resistance/Measurements/Vdc/Displ" />
		<xsl:param name="secCurrent" select="Tests/Cards/Resistance/Measurements/Idc/Displ" />

		<xsl:param name="primResistanceMeas" select="Tests/Cards/PrimaryResistance/Measurements/Rmeas/Displ" />
		<xsl:param name="primResistanceRef" select="Tests/Cards/PrimaryResistance/Measurements/Rref/Displ" />
		<xsl:param name="primTemperatureMeas" select="Tests/Cards/PrimaryResistance/Settings/Tmeas/Displ" />
		<xsl:param name="primTemperatureRef" select="Tests/Cards/PrimaryResistance/Settings/Tref/Displ" />
		<xsl:param name="primVoltage" select="Tests/Cards/PrimaryResistance/Measurements/Vdc/Displ" />
		<xsl:param name="primCurrent" select="Tests/Cards/PrimaryResistance/Measurements/Idc/Displ" />

		<div name="ResistanceResults">
			<h2 rid="CARD_RESISTANCE_000">Resistance</h2>

			<!--Show status info-->
			<xsl:if test="$ResistanceCard/Status/Card/Select = '1'">
				<table>
					<tr>
						<td class="tableDivider" rid="CARD_RESISTANCE_022" colspan="4">Secondary Winding:</td>
					</tr>
					<!-- print only in case of error -->
					<xsl:call-template name="General_Hardware_Status">
						<!-- pass the xml node containing the status to the template -->
						<xsl:with-param name="valuePath" select="$ResistanceCard/Status/Hardware" />
					</xsl:call-template>

					<!-- print only in case of error -->
					<xsl:if test="$ResistanceCard/Status/Hardware/Status = '1'">
						<tr>
							<td class="descriptor" rid="CARD_RESISTANCE_004">R-meas:</td>
							<td class="decimalValue">
								<xsl:value-of select="$secResistanceMeas" />
							</td>
							<td class="descriptor" rid="CARD_RESISTANCE_008">T-meas:</td>
							<td>
								<xsl:value-of select="$secTemperatureMeas" />
							</td>
						</tr>
						<tr>
							<td class="descriptor"  rid="CARD_RESISTANCE_010">R-ref:</td>
							<td class="decimalValue">
								<xsl:value-of select="$secResistanceRef" />
							</td>
							<td class="descriptor" rid="CARD_RESISTANCE_009">T-ref:</td>
							<td>
								<xsl:value-of select="$secTemperatureRef" />
							</td>
						</tr>
					</xsl:if>
				</table>
			</xsl:if>

			<xsl:if test="$PrimaryResistanceCard/Status/Card/Select = '1'">
				<table>
					<tr>
						<td class="tableDivider" rid="CARD_RESISTANCE_021" colspan="4">Primary Winding:</td>
					</tr>
					<!-- print only in case of error -->
					<xsl:call-template name="General_Hardware_Status">
						<xsl:with-param name="valuePath" select="$PrimaryResistanceCard/Status/Hardware" />
					</xsl:call-template>

					<xsl:if test="$PrimaryResistanceCard/Status/Hardware/Status = '1'">
						<tr>
							<td class="descriptor" rid="CARD_RESISTANCE_004">R-meas:</td>
							<td class="decimalValue">
								<xsl:value-of select="$primResistanceMeas" />
							</td>
							<td class="descriptor" rid="CARD_RESISTANCE_008">T-meas:</td>
							<td>
								<xsl:value-of select="$primTemperatureMeas" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_RESISTANCE_010">R-ref:</td>
							<td class="decimalValue">
								<xsl:value-of select="$primResistanceRef" />
							</td>
							<td class="descriptor" rid="CARD_RESISTANCE_009">T-ref:</td>
							<td>
								<xsl:value-of select="$primTemperatureRef" />
							</td>
						</tr>
					</xsl:if>
				</table>
			</xsl:if>

		</div>

	</xsl:template>

	<xsl:template name="Card_Excitation">
		<!--Card Excitation -->
		<!--Last used text ID for card excitation is 118-->
		<xsl:param name="ExcitationCard" select="Tests/Cards/Excitation" />

		<xsl:if test="$ExcitationCard/Status/Card/Select = '1'">
			<h2 rid="CARD_EXCITATION_000">Excitation:</h2>

			<!--Show status info-->
			<table>
				<!-- print only in case of error -->
				<xsl:call-template name="General_Hardware_Status">
					<xsl:with-param name="valuePath" select="$ExcitationCard/Status/Hardware" />
				</xsl:call-template>

				<!-- print only in case of overload -->
				<xsl:if test="$ExcitationCard/Measurements/Overload != 0">
					<tr>
						<td class="descriptor" rid="CARD_EXCITATION_002">Overload:</td>
						<xsl:choose>
							<xsl:when test="$ExcitationCard/Measurements/Overload = 0">
								<td class="value" rid="CARD_EXCITATION_003">no</td>
							</xsl:when>
							<xsl:when test="$ExcitationCard/Measurements/Overload = 1">
								<td class="value" rid="CARD_EXCITATION_004">yes</td>
							</xsl:when>
						</xsl:choose>
					</tr>
				</xsl:if>
			</table>

			<xsl:if test="$ExcitationCard/Status/Hardware/Status = '1'">
				<div class="dataBlockEnd">
					<table>

						<!-- print knee point tables -->
						<xsl:call-template name="Excitation_Kneepoints">
							<xsl:with-param name="ExcitationCard" select="$ExcitationCard" />
						</xsl:call-template>

						<!-- Ktd Calculation for 60044-6-->
						<xsl:if test="TestObject/Standard = '60044-6' and TestObject/Class != 'TPS'">
							<tr>
								<td class="descriptor" rid="CARD_EXCITATION_105">Ktd Calculation:</td>
								<xsl:choose>
									<xsl:when test="TestObject/KtdCalc/Val = 0">
										<td class="value" rid="CARD_EXCITATION_106">acc. 60044-6</td>
									</xsl:when>
									<xsl:when test="TestObject/KtdCalc/Val = 1">
										<td class="value" rid="CARD_EXCITATION_107">acc. Omicron</td>
									</xsl:when>
									<xsl:when test="TestObject/KtdCalc/Val = 2">
										<td class="value" rid="CARD_EXCITATION_120">acc. GB 16847 (1997)</td>
									</xsl:when>
								</xsl:choose>
							</tr>
						</xsl:if>

						<tr>
							<td class="tableDivider" rid="CARD_EXCITATION_006" colspan="4">Results:</td>
						</tr>

						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_022">Kr:</td>
							<td>
								<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Kr/Displ" />
							</td>

							<td class="descriptor" rid="CARD_EXCITATION_023">Lm:</td>
							<td>
								<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Lu/Displ" />
							</td>
						</tr>

						<tr>
							<td class="descriptor"/>
							<td/>

							<td class="descriptor" rid="CARD_EXCITATION_024">Ls:</td>
							<td>
								<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ls/Displ" />
							</td>
						</tr>

						<!-- 60044-1 and PX -->
						<xsl:if test="TestObject/Standard = '60044-1' and starts-with(TestObject/Class,'PX')">
							<tr>
								<td class="descriptor" rid="CARD_EXCITATION_100">Ek:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ual/Displ" />
								</td>

								<td class="descriptor" rid="CARD_EXCITATION_101">Ie:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ial/Displ" />
								</td>
							</tr>
							<tr>
								<td class="descriptor" rid="CARD_EXCITATION_111">E1:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ual1/Displ" />
								</td>

								<td class="descriptor" rid="CARD_EXCITATION_112">Ie1:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ial1/Displ" />
								</td>
							</tr>
						</xsl:if>

						<!-- 60044-6 and TPS -->
						<xsl:if test="TestObject/Standard = '60044-6' and TestObject/Class = 'TPS'">
							<tr>
								<td class="descriptor" rid="CARD_EXCITATION_102">V-al:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ual/Displ" />
								</td>

								<td class="descriptor" rid="CARD_EXCITATION_103">I-al:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ial/Displ" />
								</td>
							</tr>
							<tr>
								<td class="descriptor" rid="CARD_EXCITATION_111">E1:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ual1/Displ" />
								</td>

								<td class="descriptor" rid="CARD_EXCITATION_112">Ie1:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ial1/Displ" />
								</td>
							</tr>
						</xsl:if>

						<!-- 61869-2 and PX, PXR -->
						<xsl:if test="TestObject/Standard = '61869-2' and starts-with(TestObject/Class,'PX')">
							<tr>
								<td class="descriptor" rid="CARD_EXCITATION_100">Ek:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ual/Displ" />
								</td>

								<td class="descriptor" rid="CARD_EXCITATION_101">Ie:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ial/Displ" />
								</td>
							</tr>
							<tr>
								<td class="descriptor" rid="CARD_EXCITATION_111">E1:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ual1/Displ" />
								</td>

								<td class="descriptor" rid="CARD_EXCITATION_112">Ie1:</td>
								<td>
									<xsl:value-of select="$ExcitationCard/Measurements/PowerRelated/Ial1/Displ" />
								</td>
							</tr>
						</xsl:if>



					</table>
				</div>

				<!-- Excitation Burden Values -->
				<div class="dataBlockEnd" name="Excitation_Burden_Values">
					<table>
						<tr>
							<td>
								<!-- Results with nominal burden -->
								<xsl:call-template name="Excitation_Nominal_Burden" />
							</td>
							<td>
								<!-- Results with operating burden -->
								<xsl:call-template name="Excitation_Operating_Burden" />
							</td>
						</tr>
					</table>
				</div>

				<!-- Excitation Table and Graph -->
				<xsl:if test="$ExcitationCard/Measurements/MeasPoints/NumPoints &gt; 0">
					<div class="dataBlockEnd" name="Excitation_table_and_graph" style="page-break-before: always">
						<table name="excitation_table">
							<tr>
								<th colspan="3" rid="CARD_EXCITATION_052">Excitation Table:</th>
							</tr>
							<tr class="blank">
								<td/>
							</tr>
							<tr>

								<td>
									<xsl:call-template name="Excitation_Table">
										<xsl:with-param name="value_path" select="$ExcitationCard/Measurements/MeasPoints" />
									</xsl:call-template>
								</td>

								<!-- show also the embedded refernece data, if available -->
								<xsl:if test="$ExcitationCard/Measurements/RefPoints/ShowReferenceData = 1">
									<td>
										<xsl:call-template name="Excitation_Table">
											<xsl:with-param name="value_path" select="$ExcitationCard/Measurements/RefPoints" />
										</xsl:call-template>
									</td>
								</xsl:if>

								<td valign="top">
									<!-- draw excitation graph -->
									<xsl:call-template name="Chart_Excitation_Curve" />
								</td>
							</tr>
						</table>
					</div>
				</xsl:if>
				<!-- Excitation Graph end -->


				<!-- Error Graph , set global parameter $enableErrorGraph to true for show graph in report-->
				<xsl:if test ="$enableErrorGraph = true()">
					<xsl:call-template name="K_Error_Graph">
						<xsl:with-param name="ExcitationCard" select="$ExcitationCard" />
					</xsl:call-template>
				</xsl:if>

			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template name="Card_Ratio">
		<!--Card Ratio -->
		<!--Last used text ID for card ratio is 104-->
		<xsl:param name="RatioCard" select="Tests/Cards/Ratio" />

		<xsl:if test="$RatioCard/Status/Card/Select = '1'">
			<h2 style="page-break-before: always" rid="CARD_RATIO_000">Ratio:</h2>

			<!--Show status info-->
			<table>
				<!-- print only in case of error -->
				<xsl:call-template name="General_Hardware_Status">
					<xsl:with-param name="valuePath" select="$RatioCard/Status/Hardware" />
				</xsl:call-template>
			</table>


			<xsl:if test="$RatioCard/Status/Hardware/Status = '1'">
				<!--TODO: implement table for operational burden, like in excitation-->
				<div class="dataBlockEnd" name="Ratio_operating_burden">
					<table>					
						<tr>
							<td class="tableDivider" colspan="2" rid="CARD_RATIO_010">Results with nominal burden:</td>
						</tr>

						<tr>
							<td class="descriptor" rid="CARD_RATIO_002">Used Burden:</td>
							<td class="decimalValue">

								<xsl:if test="TestObject/NominalPower/Power/Displ!='?'">
									<xsl:value-of select="concat(format-number(TestObject/NominalPower/Power/Val,'#0.0#'),' VA')" />
									<xsl:text disable-output-escaping="yes"/>
									<IDTag rid="CARD_RATIO_003">&#160;<span>cos &#966;:</span>&#160;</IDTag>
									<xsl:text disable-output-escaping="yes"/>
									<xsl:value-of select="format-number(TestObject/NominalPower/CosPhi/Displ,'#0.0#')" />
								</xsl:if>
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_RATIO_004">Used I-p:</td>
							<td class="decimalValue">
								<xsl:value-of select="$RatioCard/Settings/Isim/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_RATIO_006">Ratio:</td>
							<td class="decimalValue">
								<xsl:value-of select="$RatioCard/Measurements/Ratio/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_RATIO_007">Deviation:</td>
							<td class="decimalValue">
								<xsl:value-of select="$RatioCard/Measurements/Deviation/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_RATIO_028">&#949;-c:</td>
							<td class="decimalValue">
								<xsl:value-of select="$RatioCard/Measurements/CompositError/Displ" />
							</td>
						</tr>
						<xsl:if test="$isIeeeStandard">
							<tr>
								<td class="descriptor" rid="CARD_RATIO_027">RCF:</td>
								<td class="decimalValue">
									<xsl:value-of select="$RatioCard/Measurements/RCF/Displ" />
								</td>
							</tr>
						</xsl:if>
						<tr>
							<td class="descriptor" rid="CARD_RATIO_022">N:</td>
							<td class="decimalValue">
								<xsl:value-of select="$RatioCard/Measurements/Ncore/Displ" />
							</td>
						</tr>
						<xsl:if test="TestObject/Class = 'PX' or TestObject/Class = 'TPS'">
							<tr>
								<td class="descriptor" rid="CARD_RATIO_100">&#949;-t:</td>
								<td class="decimalValue">
									<xsl:value-of select="$RatioCard/Measurements/TurnsError/Displ" />
								</td>
							</tr>
						</xsl:if>
						<tr>
							<td class="descriptor" rid="CARD_RATIO_008">Phase:</td>
							<td class="decimalValue">
								<xsl:value-of select="$RatioCard/Measurements/Phase/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_RATIO_009">Polarity:</td>

							<td class="decimalValue">
								<xsl:choose>
									<xsl:when test="$RatioCard/Measurements/Polarity = '1'">
										<IDTag rid="CARD_RATIO_024">OK</IDTag>
									</xsl:when>
									<xsl:when test="$RatioCard/Measurements/Polarity = '-1'">
										<IDTag rid="CARD_RATIO_025">Failed</IDTag>
									</xsl:when>
									<xsl:when test="$RatioCard/Measurements/Polarity = '0'">
										<IDTag rid="CARD_RATIO_026">n/a</IDTag>
									</xsl:when>
								</xsl:choose>
							</td>
						</tr>
					</table>
				</div>

				<!--Print Ratio and Phase tables-->
				<xsl:if test="not($RatioCard/Measurements/AccuracyNomBurden/NumRows &gt; 0)">
					<!--is only shown, if the node AccuracyNomBurden is not available (version older then 4.10)-->
					<xsl:call-template name="Ratio_Accuracy_Tables">
						<xsl:with-param name="RatioCard" select="$RatioCard" />
					</xsl:call-template>
				</xsl:if>

				<xsl:if test="$RatioCard/Measurements/AccuracyNomBurden/NumRows &gt; 0">
					<!--is only shown, if available (from version 4.10 or newer)-->
					<xsl:call-template name="Ratio_Extended_Accuracy_Tables">
						<xsl:with-param name="RatioCard" select="$RatioCard" />
					</xsl:call-template>
				</xsl:if>
				<xsl:call-template name="Card_Multi_Ratio" />
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template name="Card_Multi_Ratio">
		<xsl:param name="NumberOfTaps" select="MultiRatio/Settings/NumberTaps" />
		<xsl:param name="secondaryCurrent" select="TestObject/Isn/Val" />
		<xsl:param name="primaryCurrent" select="TestObject/Ipn/Val" />
		<xsl:param name="tapInUse" select="MultiRatio/Settings/TapInUse" />
		<xsl:param name="commonTap" select="MultiRatio/Settings/CommonTap" />

		<xsl:if test="$ratioType = 'MultiRatio'">


			<h2 style="page-break-before: always" rid="CARD_MULTI_RATIO_000">Multi Ratio:</h2>
			<div class="dataBlockEnd" name="multi-ratio_configuration">
				<table>
					<tr>
						<td class="tableDivider" rid="CARD_MULTI_RATIO_017" colspan="4">Configuration:</td>
					</tr>
					<tr>
						<td  class="descriptor" rid="CARD_MULTI_RATIO_010">No. of Taps:</td>
						<td class="decimalValue">
							<xsl:value-of select="$NumberOfTaps" />
						</td>
					</tr>
					<tr>
						<td  class="descriptor" rid="CARD_MULTI_RATIO_016">Common Tap:</td>
						<td class="decimalValue">
						X<xsl:value-of select="$commonTap" />
						</td>
					</tr>
					<tr>
						<td  class="descriptor" rid="CARD_MULTI_RATIO_002">Tap in Use:</td>
						<td class="decimalValue">
							<xsl:value-of select="$tapInUse" />
						</td>
					</tr>

				</table>
			</div>

			<div class="dataBlockEnd" name="multi-ratio_results">
				<table class="valueTable">
					<tr>
						<th  rid="CARD_MULTI_RATIO_006">Tap</th>
						<th rid="CARD_MULTI_RATIO_005">Ratio</th>
						<th rid="CARD_MULTI_RATIO_018">Nominal<br/> Burden</th>
						<th rid="CARD_MULTI_RATIO_007">cos &#966;</th>
						<th rid="CARD_MULTI_RATIO_011">Current<br/> Ratio</th>
						<th rid="CARD_MULTI_RATIO_012">Ratio<br/> Error [%]</th>
						<th rid="CARD_MULTI_RATIO_015">Phase<br/> Error [']</th>
						<th rid="CARD_MULTI_RATIO_013">R-meas. [&#8486;]</th>
						<th rid="CARD_MULTI_RATIO_014">R-ref. [&#8486;]</th>

						<th/>

						<!-- all taps -->
						<xsl:for-each select="MultiRatio/Measurements/*[starts-with(name(),'TapX')]">
							<xsl:sort select="name()"/>
							<xsl:variable name="tapName" select="name()" />
							<xsl:variable name="iPrim" select="../../Settings/*[name()=$tapName]/Iprim" />
							<xsl:variable name="testEnabled" select="../../Settings/*[name()=$tapName]/TestEnable" />
							<tr>
								<td>
									<xsl:value-of select="substring(name(),4)" />
								</td>
								<!-- only print enabled taps -->
								<xsl:if test="$testEnabled = 1">
									<td class="decimalValue">
										<xsl:value-of select="format-number(Ratio/Ncore * $secondaryCurrent,'#')" />:<xsl:value-of select="format-number($secondaryCurrent,'#')" />
									</td>
									<td class="decimalValue">
										<xsl:value-of select="format-number(../../Settings/*[name()=$tapName]/Power,'#0.0#')" /> VA
									</td>
									<td class="decimalValue">
										<xsl:value-of select="format-number(../../Settings/*[name()=$tapName]/CosPhi,'#0.0#')" />
									</td>
									<td class="decimalValue">
										<xsl:value-of select="format-number(Ratio/CurrentRatio/Ipn,'#0')" />:<xsl:value-of select="format-number(Ratio/CurrentRatio/Isec,'#0.000')" />
									</td>
									<td class="decimalValue">
										<xsl:value-of select="format-number(Ratio/RatioError,'#0.000')" />
									</td>
									<td class="decimalValue">
										<xsl:value-of select="format-number(Ratio/PhaseError,'#0.000')" />
									</td>
									<td class="decimalValue">
										<xsl:value-of select="format-number(Resistance/Rmeas,'#0.000')" />
									</td>
									<td class="decimalValue">
										<xsl:value-of select="format-number(Resistance/Rref,'#0.000')" />
									</td>
									<xsl:if test="contains(name(),$tapInUse)">
										<td rid="CARD_MULTI_RATIO_003">Tap in Use</td>
									</xsl:if>
									<xsl:if test="not(contains(name(),$tapInUse))">
										<td/>
									</xsl:if>
								</xsl:if>
							</tr>

						</xsl:for-each>
					</tr>
				</table>
			</div>
		</xsl:if>

	</xsl:template>


	<!--  *****    Card Settings Value Templates   *****  -->

	<xsl:template name="Card_Settings_Standard">
		<td class="descriptor" rid="CARD_OBJECT_008">Applied Standard:</td>
		<td class="value">
			<xsl:value-of select="$standardName" />
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Core_Type">
		<td class="descriptor" rid="CARD_OBJECT_009">Core Type:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/CoreType = 'P'">
					<IDTag rid="CARD_OBJECT_036">Protection CT</IDTag>
				</xsl:when>
				<xsl:when test="TestObject/CoreType = 'M'">
					<IDTag rid="CARD_OBJECT_037">Metering CT</IDTag>
				</xsl:when>
				<xsl:when test="TestObject/CoreType = '?'">
					<IDTag rid="CARD_OBJECT_039">?*</IDTag>
				</xsl:when>
			</xsl:choose>
			<xsl:if test="TestObject/CoreGuess=1">
				<sup> ?*</sup>
			</xsl:if>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Class">
		<td class="descriptor" rid="CARD_OBJECT_010">Class:</td>
		<td class="value">
			<xsl:value-of select="TestObject/Class" />
			<xsl:if test="TestObject/ClassGuess=1">
				<sup> ?*</sup>
			</xsl:if>
			<xsl:if test="TestObject/ClassAssessAt = 1">
			@<xsl:call-template name="Settings_Guessed_Values_Mandatory">
					<xsl:with-param name="valuePath" select="TestObject/NominalPower/Power" />
					<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
					<xsl:with-param name="unit" select="'VA'" />
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="not(TestObject/ClassString = '')">
							 - 
				<xsl:value-of select="TestObject/ClassString" />
				<!--<xsl:if test="TestObject/ClassGuess=1">
					<sup> ?*</sup>
				</xsl:if>-->
			</xsl:if>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ipn">
		<td class="descriptor" rid="CARD_OBJECT_006">Primary Current I-pn:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ipn" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'A'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Isn">
		<td class="descriptor" rid="CARD_OBJECT_007">Secondary Current I-sn:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Isn" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'A'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Frequency">
		<td class="descriptor" rid="CARD_OBJECT_012">Frequency:</td>
		<td class="value">
			<xsl:call-template name="Format_Values">
				<xsl:with-param name="valuePath" select="TestObject/Frequency" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0'" />
				<xsl:with-param name="unit" select="'Hz'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Nominal_Burden">
		<td class="descriptor" rid="CARD_OBJECT_013">Nominal Burden:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values_Mandatory">
				<xsl:with-param name="valuePath" select="TestObject/NominalPower/Power" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'VA'" />
			</xsl:call-template>
			<xsl:text disable-output-escaping="yes"/>&#160;<span>cos &#966;:</span>&#160;<xsl:text disable-output-escaping="yes"/>
			<xsl:call-template name="Format_Values">
				<xsl:with-param name="valuePath" select="TestObject/NominalPower/CosPhi" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Operating_Burden">
		<td class="descriptor" rid="CARD_OBJECT_014">Operating Burden:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/NominalBurden/Power" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'VA'" />
			</xsl:call-template>
			<xsl:if test="TestObject/NominalBurden/Power/Displ != '?'">
				<xsl:text disable-output-escaping="yes"/>&#160;<span>cos &#966;:</span>&#160;<xsl:text disable-output-escaping="yes"/>
				<xsl:call-template name="Settings_Guessed_Values">
					<xsl:with-param name="valuePath" select="TestObject/NominalBurden/CosPhi" />
					<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				</xsl:call-template>
			</xsl:if>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Low_Burden_Limit">
		<td class="descriptor" rid="CARD_OBJECT_074">min. VA at M-cores Isn 5A:</td>
		<td class="value">
			<xsl:call-template name="Format_Values">
				<xsl:with-param name="valuePath" select="TestObject/MinimalPower" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'VA'" />
			</xsl:call-template>
		</td>
	</xsl:template>
	
	<xsl:template name="Card_Settings_Rated_Burden_Below_1VA">
		<td class="descriptor" rid="CARD_OBJECT_075">Rated burdens &lt; 1VA:</td>
		<td class="value" rid="CARD_OBJECT_076">Enable</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ext">
		<td class="descriptor" rid="CARD_OBJECT_058">Ext. I-pn:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ext" />
				<xsl:with-param name="numberFormatPattern" select="'#0'" />
				<xsl:with-param name="unit" select="'%'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ext_VA">
		<td class="descriptor" rid="CARD_OBJECT_070">Ext. VA:</td>
		<td class="value">
			<xsl:if test="TestObject/ExtVA/Val = 1">
				<IDTag rid="CARD_BURDEN_004">yes</IDTag>
			</xsl:if>
			<xsl:if test="TestObject/ExtVA/Val != 1">
				<IDTag rid="CARD_BURDEN_003">no</IDTag>
			</xsl:if>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Rct">
		<td class="descriptor" rid="CARD_OBJECT_043">Rct:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Rct" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
				<xsl:with-param name="unit" select="'&#8486;'" />
			</xsl:call-template>
		(<xsl:value-of select="//Object[CPLine = 'CT-Analyzer']/Tests/Cards/Resistance/Settings/Tref/Displ" />)
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ts">
		<td class="descriptor" rid="CARD_OBJECT_028">Ts:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ts" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
				<xsl:with-param name="unit" select="s" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Tp">
		<td class="descriptor" rid="CARD_OBJECT_020">Tp:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/Tp" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
						<xsl:with-param name="mandatory" select="true()" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Settings_Guessed_Values">
						<xsl:with-param name="valuePath" select="TestObject/Tp" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ktd">
		<td class="descriptor" rid="CARD_OBJECT_019">Ktd:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/Ktd" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
						<xsl:with-param name="mandatory" select="true()" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/Ktd" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_K">
		<td class="descriptor" rid="CARD_OBJECT_044">K:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/K" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
				<xsl:with-param name="unit" select="''" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_tal1">
		<td class="descriptor" rid="CARD_OBJECT_022">t-al1:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/tal1" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
						<xsl:with-param name="mandatory" select="true()" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Settings_Guessed_Values">
						<xsl:with-param name="valuePath" select="TestObject/tal1" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_tal2">
		<td class="descriptor" rid="CARD_OBJECT_023">t-al2:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/tal2" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
						<xsl:with-param name="mandatory" select="true()" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Settings_Guessed_Values">
						<xsl:with-param name="valuePath" select="TestObject/tal2" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_t1">
		<td class="descriptor" rid="CARD_OBJECT_024">t1:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/t1" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
						<xsl:with-param name="mandatory" select="true()" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Settings_Guessed_Values">
						<xsl:with-param name="valuePath" select="TestObject/t1" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_t2">
		<!--<xsl:call-template name="Settings_Guessed_Values">
			<xsl:with-param name="valuePath" select="TestObject/t2" />
			<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
			<xsl:with-param name="unit" select="'s'" />
		</xsl:call-template>-->
	</xsl:template>

	<xsl:template name="Card_Settings_tfr">
		<td class="descriptor" rid="CARD_OBJECT_026">tfr:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/tfr" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
						<xsl:with-param name="mandatory" select="true()" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Settings_Guessed_Values">
						<xsl:with-param name="valuePath" select="TestObject/tfr" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Duty_Cycle">
		<td class="descriptor" rid="CARD_OBJECT_021">Duty cycle:</td>
		<td class="value">
			<xsl:value-of select="TestObject/Sequence" />
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_FS">
		<td class="descriptor" rid="CARD_OBJECT_040">FS:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/FS" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="''" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_ALF">
		<td class="descriptor" rid="CARD_EXCITATION_019">ALF:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/ALF" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="''" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Vb">
		<td class="descriptor" rid="CARD_OBJECT_055">Vb:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/VB" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'V'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_RF">
		<td class="descriptor" rid="CARD_OBJECT_057">RF:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/RF" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
				<xsl:with-param name="unit" select="''" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Re20xIsn">
		<td class="descriptor" rid="CARD_OBJECT_056">&#949; at 20*Isn</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Re20xIsn" />
				<xsl:with-param name="numberFormatPattern" select="'#0'" />
				<xsl:with-param name="unit" select="'%'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Kx">
		<td class="descriptor" rid="CARD_EXCITATION_040">Kx:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Kx" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00'" />
				<xsl:with-param name="unit" select="'A'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Kssc">
		<td class="descriptor" rid="CARD_OBJECT_011">Kssc:</td>
		<td class="value">
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Settings_Values">
						<xsl:with-param name="valuePath" select="TestObject/Kssc" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
						<!--<xsl:with-param name="mandatory" select="true()" />-->
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Settings_Guessed_Values">
						<xsl:with-param name="valuePath" select="TestObject/Kssc" />
						<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
						<xsl:with-param name="unit" select="''" />
						<xsl:with-param name="invalidPattern" select="-1.00" />
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<!--only for IEC 61869-2-->
	<xsl:template name="Card_Settings_SpecMethod">
		<td class="descriptor" rid="CARD_OBJECT_071">Spec. Method:</td>
		<td class="value">
			<xsl:if test="TestObject/TPSpecMtd = 'Standard'">
				<IDTag rid="CARD_OBJECT_072">by Duty</IDTag>
			</xsl:if>
			<xsl:if test="TestObject/TPSpecMtd = 'Altern'">
				<IDTag rid="CARD_OBJECT_073">by Ktd</IDTag>
			</xsl:if>
			<!--		(<IDTag rid="undefined">
				<xsl:value-of select="TestObject/TPSpecMtd" />
			</IDTag>)-->
		</td>
	</xsl:template>


	<xsl:template name="Card_Settings_Val">
		<td class="descriptor" rid="CARD_OBJECT_018">V-al:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ual" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00'" />
				<xsl:with-param name="unit" select="'V'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ial">
		<td class="descriptor" rid="CARD_OBJECT_017">I-al:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ial" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
				<xsl:with-param name="unit" select="'A'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Val1">
		<xsl:call-template name="Settings_Guessed_Values">
			<xsl:with-param name="valuePath" select="TestObject/Ual1" />
			<xsl:with-param name="numberFormatPattern" select="'#0.00'" />
			<xsl:with-param name="unit" select="'V'" />
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="Card_Settings_Ial1">
		<xsl:call-template name="Settings_Guessed_Values">
			<xsl:with-param name="valuePath" select="TestObject/Ial1" />
			<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
			<xsl:with-param name="unit" select="'A'" />
		</xsl:call-template>
	</xsl:template>


	<xsl:template name="Card_Settings_Ek">
		<td class="descriptor" rid="CARD_OBJECT_041">Ek:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ual" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00'" />
				<xsl:with-param name="unit" select="'V'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_E1">
		<td class="descriptor" rid="CARD_OBJECT_045">E1:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ual1" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00'" />
				<xsl:with-param name="unit" select="'V'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ie">
		<td class="descriptor" rid="CARD_OBJECT_042">Ie:</td>
		<td class="value">
			<xsl:call-template name="Settings_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ial" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'mA'" />
				<xsl:with-param name="factor" select="1000.0" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ie1">
		<td class="descriptor" rid="CARD_OBJECT_046">Ie1:</td>
		<td class="value">
			<xsl:call-template name="Settings_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ial1" />
				<xsl:with-param name="numberFormatPattern" select="'#0.0#'" />
				<xsl:with-param name="unit" select="'mA'" />
				<xsl:with-param name="factor" select="1000.0" />
			</xsl:call-template>
		</td>
	</xsl:template>


	<xsl:template name="Card_Settings_Vk">
		<td class="descriptor" rid="CARD_OBJECT_065">Vk:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ual" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00'" />
				<xsl:with-param name="unit" select="'V'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ik">
		<td class="descriptor" rid="CARD_OBJECT_067">Ik:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ial" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
				<xsl:with-param name="unit" select="'A'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Vk1">
		<td class="descriptor" rid="CARD_OBJECT_066">Vk1:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ual1" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00'" />
				<xsl:with-param name="unit" select="'V'" />
			</xsl:call-template>
		</td>
	</xsl:template>

	<xsl:template name="Card_Settings_Ik1">
		<td class="descriptor" rid="CARD_OBJECT_068">Ik1:</td>
		<td class="value">
			<xsl:call-template name="Settings_Guessed_Values">
				<xsl:with-param name="valuePath" select="TestObject/Ial1" />
				<xsl:with-param name="numberFormatPattern" select="'#0.00#'" />
				<xsl:with-param name="unit" select="'A'" />
			</xsl:call-template>
		</td>
	</xsl:template>




	<!--  *****    Card Assessment Value Templates   *****  -->

	<xsl:template name="Card_Ass_Total">
		<th>
			<tr>
				<th  class="tableDivider2" rid="CARD_ASS_010">Assessment</th>
				<th align="center" rid="CARD_ASS_002">Auto</th>
				<th align="center" rid="CARD_ASS_003">Manual</th>
			</tr>
		</th>

		<tr>
			<td/>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/General/Status/Assessments/Total" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Class">
		<!-- Class -->
		<tr>
			<td rid="CARD_ASS_039">Class</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/Class" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Rct">
		<!-- Rct -->
		<tr>
			<td rid="CARD_ASS_101">Rct</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Resistance/Status/Assessments/RCT" />
			</xsl:call-template>

		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Ratio_Error">
		<!-- Ratio Error -->
		<tr>
			<td>...&#949;</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/RatioError" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Delta_Phi">
		<!-- Delta Phi -->
		<tr>
			<td>...&#916;&#966;</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/PhaseError" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_FS">
		<!-- FS -->
		<tr>
			<td rid="CARD_ASS_011">FS</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/FS" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_FSi">
		<!-- FSi -->
		<tr>
			<td rid="CARD_ASS_123">FSi</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/FSi" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Ts">
		<!-- Ts -->
		<tr>
			<td rid="CARD_ASS_060">Ts</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Ts" />
			</xsl:call-template>			
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Kr">
		<!-- Kr -->
		<tr>
			<td rid="CARD_ASS_067">Kr</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Kr" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Turns_Error">
		<!-- Turns Error -->
		<tr>
			<td>...&#949;-t</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/TurnsError" />
			</xsl:call-template>
		</tr>
	</xsl:template>	

	<xsl:template name="Card_Ass_Ek">
		<!-- Ek -->
		<tr>
			<td rid="CARD_ASS_100">Ek</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Val2" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Ie">
		<!-- Ie1 -->
		<tr>
			<td rid="CARD_ASS_125">Ie</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Ial2" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Ie1">
		<!-- Ie1 -->
		<tr>
			<td rid="CARD_ASS_132">Ie1</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Ie1" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Vk-Ik">
		<!-- Ie1 -->
		<tr>
			<td rid="CARD_ASS_133">Vk/Ik</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Ial2" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Vk1-Ik1">
		<!-- Ie1 -->
		<tr>
			<td rid="CARD_ASS_134">Vk1/Ik1</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Ie1" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Kx">
		<!-- Kx -->
		<tr>
			<td rid="CARD_ASS_092">Kx</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Kssc" />
			</xsl:call-template>
		</tr>	
	</xsl:template>

	<xsl:template name="Card_Ass_Composite_Error">
		<!-- Composite Error -->
		<tr>
			<td>...&#949;-c</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/CompositError" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_ALF">
		<!-- ALF -->
		<tr>
			<td rid="CARD_ASS_035">ALF</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/ALF" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_ALFi">
		<!-- ALFi -->
		<tr>
			<td rid="CARD_ASS_124">ALFi</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/ALFi" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_U_Al">
		<!-- Ual -->
		<tr>
			<td rid="CARD_ASS_116">V-al</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Val2" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_I_Al">
		<!-- Ial -->
		<tr>
			<td rid="CARD_ASS_109">I-al</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Ial2" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_K_x_Kssc">
		<!-- K*Kssc -->
		<tr>
			<td align="left" rid="CARD_ASS_090">K*Kssc</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Kssc" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Peak_Error">
		<!-- Peak Error -->
		<tr>
			<td>...&#949;-p</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/PeakError" />
			</xsl:call-template>
		</tr>
	</xsl:template>
	
	<xsl:template name="Card_Ass_Peak_Error_AC">
		<!-- Peak Error AC-->
		<tr>
			<td>...&#949;-p-ac</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/PeakErrorAC" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Ktd_x_Kssc">
		<!-- Ktd*Kssc -->
		<tr>
			<td align="left" rid="CARD_ASS_004">Ktd*Kssc</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Kssc" />
			</xsl:call-template>

		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Re_20_Isn">
		<!-- Ratio Error at 20*Isn -->
		<tr>
			<td rid="CARD_ASS_126">...&#949; at 20*Isn</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/ErrorAt20Isn" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Re_Vb">
		<!-- Ratio Error at Vb -->
		<tr>
			<td rid="CARD_ASS_127">...&#949; at Vb</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/ErrorAtVb" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Re_Isn">
		<!-- Ratio Error at Vb -->
		<tr>
			<td rid="CARD_ASS_130">...&#949; at Isn</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/ErrorAtIsn" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_U_knee">
		<!-- Uknee -->
		<tr>
			<td rid="CARD_ASS_128">...V-knee</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/Vknee" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Vb">
		<!-- Vb -->
		<tr>
			<td rid="CARD_ASS_129">Vb</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Excitation/Status/Assessments/VB" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_RCF">
		<!-- RCF -->
		<tr>
			<td rid="CARD_ASS_131">RCF</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="Tests/Cards/Ratio/Status/Assessments/RCF" />
			</xsl:call-template>
		</tr>
	</xsl:template>

	<xsl:template name="Card_Ass_Burden">
		<!-- Burden -->
		<tr>
			<td rid="CARD_ASS_053">Burden</td>
			<xsl:call-template name="Assessment_Result">
				<xsl:with-param name="result_path" select="TTests/Cards/Burden/Status/Assessments/Burden" />
			</xsl:call-template>
		</tr>
	</xsl:template>


	<!--provide a path to a values that can be guessed. If the value is guessed a questionmark is written-->
	<!--this is used in the settings section to indicate guessed values-->
	<!--obsolete -> use Settings_Values template-->
	<xsl:template name="Settings_Guessed_Values">
		<!--TODO: refactor code to use only template "Settings_Values"-->
		<xsl:param name="valuePath" />
		<xsl:param name="numberFormatPattern" />
		<xsl:param name="unit" />
		<xsl:param name="invalidPattern" />

		<xsl:choose>
			<xsl:when test="$valuePath/Val = $invalidPattern">
				<IDTag rid="OPTIONAL_008">not defined</IDTag>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="format-number($valuePath/Val,$numberFormatPattern)" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="$unit" />
		<xsl:if test="$valuePath/Guess=1">
			<sup> ?</sup>
		</xsl:if>
	</xsl:template>

	<!--provide a path to a values that can be guessed. If the value is guessed a questionmark is written-->
	<!--this is used in the settings section to indicate guessed values-->
	<!--obsolete -> use Settings_Values template-->
	<xsl:template name="Settings_Guessed_Values_Mandatory">
		<!--TODO: refactor code to use only template "Settings_Values"-->
		<xsl:param name="valuePath" />
		<xsl:param name="numberFormatPattern" />
		<xsl:param name="unit" />
		<xsl:param name="invalidPattern" />

		<xsl:choose>
			<xsl:when test="$valuePath/Val = $invalidPattern">
				<IDTag rid="OPTIONAL_008">not defined</IDTag>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="format-number($valuePath/Val,$numberFormatPattern)" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="$unit" />
		<xsl:if test="$valuePath/Guess=1">
			<sup> ?*</sup>
		</xsl:if>
	</xsl:template>

	<!--provide a path to a values that can be guessed. If the value is guessed a questionmark is written-->
	<!--this is used in the settings section to indicate guessed values-->
	<xsl:template name="Settings_Values">
		<!--a XML node-->
		<xsl:param name="valuePath" />
		<!--pattern for the function format-number()-->
		<xsl:param name="numberFormatPattern" />
		<!--string that is placed directly behind the value-->
		<xsl:param name="unit" />
		<!--If the values matches this defined pattern the sheet shows not defined-->
		<xsl:param name="invalidPattern" />
		<!--true() for mandatory, ignored on other values-->
		<xsl:param name="mandatory" />
		<!--Use to achieve a scaling to units with multipliers, e.g. factor = 1000 to change A -> mA-->
		<xsl:param name="factor" select="1.0"/>

		<xsl:choose>
			<xsl:when test="$valuePath/Val = $invalidPattern">
				<IDTag rid="OPTIONAL_008">not defined</IDTag>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="format-number($valuePath/Val * $factor,$numberFormatPattern)" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="$unit" />
		<xsl:if test="$valuePath/Guess=1">
			<sup> ?</sup>
		</xsl:if>
		<xsl:if test="$mandatory=true()">
			<sup> *</sup>
		</xsl:if>
	</xsl:template>

	<!--provide a path to a values that should be formatted. The value has to be a number-->
	<xsl:template name="Format_Values">
		<xsl:param name="valuePath" />
		<xsl:param name="numberFormatPattern" />
		<xsl:param name="unit" />

		<xsl:value-of select="format-number($valuePath/Val,$numberFormatPattern)" />
		<xsl:value-of select="$unit" />
	</xsl:template>

	<!-- +++++ Assessment for tests - to reduce the redundancy of the OK and Not Ok +++ needs to be finished -->
	<!-- IDEA: pass a value to the template (-1,0,1) and replace it with a written form -->
	<!-- reduce the code and translation effort -->
	<xsl:template name="Assessment_Result">
		<!-- this parameters (a XML node) has to be passed  by the template call -->
		<xsl:param name="result_path" />


		<xsl:param name="result_auto">
			<xsl:value-of select="$result_path/Auto" />
		</xsl:param>
		<xsl:param name="result_manual">
			<xsl:value-of select="$result_path/Manual" />
		</xsl:param>

		<!-- translate the integer values into a human readable form -->
		<td class="assessment">
			<xsl:choose>
				<xsl:when test="$result_auto = '1'">
					<IDTag rid="CARD_ASS_057">Passed</IDTag>
				</xsl:when>
				<xsl:when test="$result_auto = '-1'">
					<IDTag rid="CARD_ASS_055">Failed</IDTag>
				</xsl:when>
				<xsl:when test="$result_auto = '0'">
					<IDTag rid="CARD_ASS_056">n/a</IDTag>
				</xsl:when>
			</xsl:choose>
		</td>
		<td class="assessment">
			<xsl:choose>
				<xsl:when test="$result_manual = '1'">
					<IDTag rid="CARD_ASS_057">Passed</IDTag>
				</xsl:when>
				<xsl:when test="$result_manual = '-1'">
					<IDTag rid="CARD_ASS_055">Failed</IDTag>
				</xsl:when>
				<xsl:when test="$result_manual = '0'">
					<!--return nothing-->
				</xsl:when>
			</xsl:choose>
		</td>

	</xsl:template>

	<!-- handles the HW status of the complete measurement -->
	<xsl:template name="General_Hardware_Status">
		<xsl:param name="valuePath" />
		<xsl:if test="$valuePath/Status != 1">
			<tr>
				<td class="descriptor" rid="CARD_RESISTANCE_001">Status Info:</td>
				<td class="value">
					<xsl:call-template name="Resolve_Status_message">
						<xsl:with-param name="status_value" select="$valuePath/Status" />
					</xsl:call-template>
				</td>
			</tr>
			<xsl:if test="$valuePath/Status = -1">
				<tr>
					<td class="descriptor">
						<xsl:choose>
							<xsl:when test="$valuePath/Priority = 1">
								<IDTag rid="CARD_RESISTANCE_014">Error:</IDTag>
							</xsl:when>
							<xsl:otherwise>
								<IDTag rid="CARD_RESISTANCE_015">Warning:</IDTag>
							</xsl:otherwise>
						</xsl:choose>
					</td>
					<td class="value">
						<xsl:value-of select="$valuePath/ErrNum" />.<xsl:value-of select="$valuePath/ErrLoc" />
					</td>
				</tr>
			</xsl:if>
		</xsl:if>

	</xsl:template>


	<!-- translate the hardware status into a human readable form -->
	<xsl:template name="Resolve_Status_message">
		<!-- this parameters (a XML node) has to be passed  by the template call -->
		<xsl:param name="status_value" />

		<!-- translate the integer values into a human readable form -->
		<xsl:choose>
			<xsl:when test="$status_value = 0">
				<IDTag rid="CARD_GENERAL_008">No results</IDTag>
			</xsl:when>
			<xsl:when test="$status_value = 1">
				<IDTag rid="CARD_GENERAL_014">Test complete</IDTag>
			</xsl:when>
			<xsl:when test="$status_value = -1">
				<IDTag rid="CARD_GENERAL_010">Test not successful</IDTag>
			</xsl:when>
			<xsl:when test="$status_value = -2">
				<IDTag rid="CARD_GENERAL_013">Test aborted</IDTag>
			</xsl:when>
			<!-- Warning: this is only for development and translation issues, this case should never be possible -->
			<xsl:otherwise>
				<IDTag rid="CARD_GENERAL_009">Test successful</IDTag>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- translate the qualifier into a human readable form -->
	<!-- 0 = invalid; 1 = calculated; 2 = measured-->
	<xsl:template name="Resolve_Measurement_Qualifier">
		<!-- this parameters (a XML node) has to be passed  by the template call -->
		<xsl:param name="status_value" />

		<!-- translate the integer values into a human readable form -->
		<xsl:choose>
			<xsl:when test="$status_value = 0">
				<IDTag rid="OPTIONAL_003">invalid</IDTag>
			</xsl:when>
			<xsl:when test="$status_value = 1">
				<IDTag rid="OPTIONAL_001">calculated</IDTag>
			</xsl:when>
			<xsl:when test="$status_value = 2">
				<IDTag rid="OPTIONAL_002">measured</IDTag>
			</xsl:when>
			<!-- Warning: this is only for development and translation issues, this case should never be possible -->
			<xsl:otherwise>
				<IDTag rid="OPTIONAL_005">unknown qualifier</IDTag>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- translate the qualifier into a human readable form -->
	<!-- 0 = value is above the detectable value (>); 1 = value is in detectable range -->
	<xsl:template name="Resolve_Value_Qualifier">
		<!-- this parameters (a XML node) has to be passed  by the template call -->
		<xsl:param name="status_value" />

		<!-- translate the integer values into a human readable form -->
		<xsl:choose>
			<xsl:when test="$status_value = 0">
				<IDTag rid="OPTIONAL_006">&gt;</IDTag>
			</xsl:when>
			<xsl:when test="$status_value = 1">
				<IDTag rid="OPTIONAL_007">ok</IDTag>
			</xsl:when>
			<!-- Warning: this is only for development and translation issues, this case should never be possible -->
			<xsl:otherwise>
				<IDTag rid="OPTIONAL_005">unknown qualifier</IDTag>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>








	<!--  *****    Card Excitation Value Templates   *****  -->

	<!-- Printing of the knee points -->
	<xsl:template name="Excitation_Kneepoints">
		<xsl:param name="ExcitationCard"/>
		<!-- Knee Points -->
		<tr>
			<td class="tableDivider" colspan="4">
				<IDTag rid="CARD_EXCITATION_009">Knee Points:</IDTag>
			</td>
		</tr>
		<tr>
			<!-- Knee point table 1 -->
			<td colspan="2">
				<table class="valueTable">
					<thead>
						<!-- print header only, if a second kneepoint is available -->
						<xsl:if test="$ExcitationCard/Measurements/KneePoints2/IEC_1/I/Val &gt; 0">
							<tr>
								<th colspan="3" rid="CARD_EXCITATION_009">Knee Points:</th>
							</tr>
						</xsl:if>
						<tr>
							<th align="left" rid="CARD_EXCITATION_010">Standard</th>
							<th align="center" rid="CARD_EXCITATION_011">V</th>
							<th align="center" rid="CARD_EXCITATION_012">I</th>
						</tr>
					</thead>
					<tbody>

						<!-- Print all knee point tables -->
						<xsl:choose>
							<xsl:when test="$standard = '60044-1'">
								<!-- 60044-1 -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints/IEC_1/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_013">IEC 60044-1</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/IEC_1/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/IEC_1/I/Displ" />
										</td>
									</tr>
								</xsl:if>
							</xsl:when>
							<xsl:when test="$standard = '60044-6'">
								<!-- 60044-6 -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints/IEC_6/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_014">IEC 60044-6</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/IEC_6/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/IEC_6/I/Displ" />
										</td>
									</tr>
								</xsl:if>
							</xsl:when>
							<xsl:when test="$standard = '61869-2'">
								<!-- 61869-2 -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints/IEC_69_2/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_122">IEC 61869-2</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/IEC_69_2/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/IEC_69_2/I/Displ" />
										</td>
									</tr>
								</xsl:if>
							</xsl:when>
							<xsl:when test="starts-with($standard,'ANSI')">
								<!-- C57.13 aka ANSI-45  -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints/ANSI_45/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_016">IEEE C57.13</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/ANSI_45/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/ANSI_45/I/Displ" />
										</td>
									</tr>
								</xsl:if>

								<!-- ANSI-30 -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints/ANSI_30/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_015">IEEE C57.13 (30&#176;)</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/ANSI_30/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints/ANSI_30/I/Displ" />
										</td>
									</tr>
								</xsl:if>
							</xsl:when>
						</xsl:choose>


					</tbody>
				</table>
			</td>
			<!-- Knee point table 1 end -->

			<!-- Knee points 2 -->
			<!-- TODO check knee ponits 2 condition  (does only affect IEC standards)-->
			<xsl:if test="not($isIeeeStandard)">
				<xsl:if test="$ExcitationCard/Measurements/KneePoints2/IEC_1/U/Val &gt; 0 or $ExcitationCard/Measurements/KneePoints2/IEC_1/I/Val &gt; 0 or&#xD;&#xA;											$ExcitationCard/Measurements/KneePoints2/IEC_6/U/Val &gt; 0 or $ExcitationCard/Measurements/KneePoints2/IEC_6/U/Val &gt; 0">
					<!--table-->

					<td class="tableDivider" colpsan ="2">
						<IDTag rid="CARD_EXCITATION_110">Knee Points 2:</IDTag>
						<table class="valueTable">
							<thead>
								<tr>
									<th align="left" rid="CARD_EXCITATION_010">Standard</th>
									<th align="center" rid="CARD_EXCITATION_011">V</th>
									<th align="center" rid="CARD_EXCITATION_012">I</th>
								</tr>
							</thead>
							<tbody>
								<!-- 60044-1 -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints2/IEC_1/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_013">IEC 60044-1</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints2/IEC_1/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints2/IEC_1/I/Displ" />
										</td>
									</tr>
								</xsl:if>

								<!-- 60044-6 -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints2/IEC_6/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_014">IEC 60044-6</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints2/IEC_6/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints2/IEC_6/I/Displ" />
										</td>
									</tr>
								</xsl:if>

								<!-- 61869-2 -->
								<xsl:if test="$ExcitationCard/Measurements/KneePoints2/IEC_69_2/U/Val &gt; 0">
									<tr>
										<td align="left" rid="CARD_EXCITATION_122">IEC 61869-2</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints2/IEC_69_2/U/Displ" />
										</td>
										<td align="right">
											<xsl:value-of select="$ExcitationCard/Measurements/KneePoints2/IEC_69_2/I/Displ" />
										</td>
									</tr>
								</xsl:if>
							</tbody>
						</table>
					</td>
					<!-- Knee points 2 end-->

				</xsl:if>
			</xsl:if>
		</tr>
	</xsl:template>



	<!-- Template to handle all velues regarding the nominal burden from the excitation part  -->
	<xsl:template name="Excitation_Nominal_Burden">
		<table>
			<tr>
				<td class="tableDivider2" rid="CARD_EXCITATION_030" colspan ="2">Results with nominal burden:</td>
			</tr>

			<tr>
				<td class="descriptor" rid="CARD_EXCITATION_007">Burden:</td>
				<td class="value">
					<xsl:value-of select="concat(format-number(TestObject/NominalPower/Power/Val,'#0.0#'),' VA')" />
					<xsl:text disable-output-escaping="yes"/>
					<IDTag rid="CARD_EXCITATION_008">&#160;<span>cos &#966;:</span>&#160;</IDTag>
					<xsl:text disable-output-escaping="yes"/>
					<xsl:value-of select="format-number(TestObject/NominalPower/CosPhi/Val,'#0.0#')" />
				</td>
			</tr>

			<xsl:call-template name="Excitation_Generic_Burden">
				<xsl:with-param name="value_path" select="Tests/Cards/Excitation/Measurements/PowerRelated " />
			</xsl:call-template>
		</table>
	</xsl:template>

	<!-- Template to handle all velues regarding the operating burden from the excitation part  -->
	<xsl:template name="Excitation_Operating_Burden">
		<table>
			<tr>
				<td class="tableDivider2" rid="CARD_EXCITATION_035" colspan="2">Results with operating burden:</td>
			</tr>

			<tr>
				<td class="descriptor" rid="CARD_EXCITATION_007">Burden:</td>
				<td class="value">
					<xsl:value-of select="concat(format-number(TestObject/NominalBurden/Power/Val,'#0.0#'),' VA')" />
					<xsl:text disable-output-escaping="yes"/>
					<IDTag rid="CARD_EXCITATION_008">&#160;<span>cos &#966;:</span>&#160;</IDTag>
					<xsl:text disable-output-escaping="yes"/>
					<xsl:value-of select="format-number(TestObject/NominalBurden/CosPhi/Val,'#0.0#')" />
				</td>
			</tr>

			<xsl:call-template name="Excitation_Generic_Burden">
				<xsl:with-param name="value_path" select="Tests/Cards/Excitation/Measurements/BurdenRelated " />
			</xsl:call-template>
		</table>
	</xsl:template>

	<!-- Generic template for nominal and operating burden, both values have the save results in different XPath locations. the path will be provided by the parameter $value_path.-->
	<xsl:template name="Excitation_Generic_Burden">
		<xsl:param name="value_path" />
		<xsl:choose>
			<!-- 60044-1 -->
			<xsl:when test="TestObject/Standard = '60044-1'">
				<xsl:choose>
					<xsl:when test="TestObject/CoreType = 'P'">
						<xsl:choose>
							<!-- PX -->
							<xsl:when test="TestObject/Class = 'PX'">
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_040">Kx:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/Kx/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/Kx/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/Ts/Displ" />
									</td>
								</tr>
							</xsl:when>
							<!-- P -->
							<xsl:otherwise>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_019">ALF:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/ALF/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/ALF/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_109">ALFi:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/ALFi/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/ALFi/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/Ts/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_121">&#949;-i:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/ErrorIndirect/Displ" /> (@ ALF = <xsl:value-of select="TestObject/ALF/Val" />)
									</td>
								</tr>


							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<!-- M -->
					<xsl:when test="TestObject/CoreType = 'M'">
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_018">FS:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/FS/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/FS/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_108">FSi:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/FSi/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/FSi/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ts/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_121">&#949;-i:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/ErrorIndirect/Displ" /> (@ FS = <xsl:value-of select="TestObject/FS/Val" />)
							</td>
						</tr>
					</xsl:when>
				</xsl:choose>
			</xsl:when>

			<!-- 60044-6 -->
			<xsl:when test="TestObject/Standard = '60044-6'">
				<tr>
					<td class="descriptor" rid="CARD_EXCITATION_017">Kssc:</td>
					<td class="decimalValue">
						<xsl:if test="$value_path/Kssc/Qualifier = '0'">&gt;</xsl:if>
						<xsl:value-of select="$value_path/Kssc/Displ" />
					</td>
				</tr>
				<xsl:choose>
					<!-- TPS -->
					<xsl:when test="TestObject/Class = 'TPS'">
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ts/Displ" />
							</td>
						</tr>
					</xsl:when>
					<!-- TPX / TPY -->
					<xsl:when test="TestObject/Class = 'TPX' or TestObject/Class = 'TPY'">
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_021">Ktd:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ktd/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ts/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_026">&#949;-peak:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/PeakInstErr/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/PeakInstErr/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_048">E-max:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/PeakEal/Displ" />
							</td>
						</tr>
					</xsl:when>
					<!-- TPZ -->
					<xsl:when test="TestObject/Class = 'TPZ'">
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_021">Ktd:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ktd/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ts/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_123">&#949;-peak-ac:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/PeakInstErrAC/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/PeakInstErrAC/Displ" />
							</td>
						</tr>
					</xsl:when>
				</xsl:choose>
			</xsl:when>

			<!-- 61869-2 -->
			<xsl:when test="TestObject/Standard = '61869-2'">
				<xsl:choose>
					<xsl:when test="TestObject/CoreType = 'P'">
						<xsl:choose>
							<!-- PX -->
							<xsl:when test="starts-with(TestObject/Class,'PX')">
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_040">Kx:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/Kx/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/Kx/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/Ts/Displ" />
									</td>
								</tr>
							</xsl:when>

							<!--TPX,TPY,TPZ-->
							<xsl:when test="starts-with(TestObject/Class,'TP')">
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_021">Ktd:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/Ktd/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_017">Kssc:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/Kssc/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/Kssc/Displ" />
									</td>
								</tr>

								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/Ts/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_026">&#949;-peak:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/PeakInstErr/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/PeakInstErr/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_123">&#949;-peak-ac:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/PeakInstErrAC/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/PeakInstErrAC/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_048">E-max:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/PeakEal/Displ" />
									</td>
								</tr>
							</xsl:when>
							<!-- P -->
							<xsl:otherwise>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_019">ALF:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/ALF/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/ALF/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_109">ALFi:</td>
									<td class="decimalValue">
										<xsl:if test="$value_path/ALFi/Qualifier = '0'">&gt;</xsl:if>
										<xsl:value-of select="$value_path/ALFi/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/Ts/Displ" />
									</td>
								</tr>
								<tr>
									<td class="descriptor" rid="CARD_EXCITATION_121">&#949;-i:</td>
									<td class="decimalValue">
										<xsl:value-of select="$value_path/ErrorIndirect/Displ" /> (@ ALF = <xsl:value-of select="TestObject/ALF/Val" />)
									</td>
								</tr>


							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<!-- M -->
					<xsl:when test="TestObject/CoreType = 'M'">
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_018">FS:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/FS/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/FS/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_108">FSi:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/FSi/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/FSi/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ts/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_121">&#949;-i:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/ErrorIndirect/Displ" /> (@ FS = <xsl:value-of select="TestObject/FS/Val" />)
							</td>
						</tr>
					</xsl:when>
				</xsl:choose>
			</xsl:when>



			<!-- ANSI -->
			<xsl:otherwise>
				<xsl:choose>
					<!-- P -->
					<xsl:when test="TestObject/CoreType = 'P'">
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_020">Vb:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/VB/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/VB/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_019">ALF:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/ALF/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/ALF/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_109">ALFi:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/ALFi/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/ALFi/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ts/Displ" />
							</td>
						</tr>
					</xsl:when>
					<!-- M -->
					<xsl:when test="TestObject/CoreType = 'M'">
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_018">FS:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/FS/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/FS/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_108">FSi:</td>
							<td class="decimalValue">
								<xsl:if test="$value_path/FSi/Qualifier = '0'">&gt;</xsl:if>
								<xsl:value-of select="$value_path/FSi/Displ" />
							</td>
						</tr>
						<tr>
							<td class="descriptor" rid="CARD_EXCITATION_043">Ts:</td>
							<td class="decimalValue">
								<xsl:value-of select="$value_path/Ts/Displ" />
							</td>
						</tr>
					</xsl:when>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>



	<!-- Printing of the excitation table -->
	<xsl:template name="Excitation_Table">
		<xsl:param name="value_path" />
		<xsl:if test="$value_path/NumPoints &gt; 0">

			<table class="valueTable clsBorder">
				<thead>
					<tr>
						<th colspan="3" rid="CARD_EXCITATION_060">Actual Values</th>
					</tr>
					<tr>
						<th align="center" rid="CARD_EXCITATION_011">V</th>
						<th align="center" rid="CARD_EXCITATION_012">I</th>
						<th align="center" rid="CARD_EXCITATION_059">L</th>
					</tr>
				</thead>

				<!-- 60044-1 -->
				<xsl:if test="TestObject/Standard = '60044-1'">
					<xsl:call-template name="Excitation_Values">
						<xsl:with-param name="caller_id" select="'60044-1'" />
						<xsl:with-param name="point_node" select="$value_path/MeasPoint" />
						<xsl:with-param name="voltage_node" select="'UCTrms'" />
						<xsl:with-param name="current_node" select="'ICTrms'" />
					</xsl:call-template>
				</xsl:if>

				<!-- 60044-6 -->
				<xsl:if test="TestObject/Standard = '60044-6'">
					<xsl:call-template name="Excitation_Values">
						<xsl:with-param name="caller_id" select="'60044-6'" />
						<xsl:with-param name="point_node" select="$value_path/MeasPoint" />
						<xsl:with-param name="voltage_node" select="'UCorerms'" />
						<xsl:with-param name="current_node" select="'ICTpeak'" />
					</xsl:call-template>
				</xsl:if>

				<!-- 61869-2 -->
				<xsl:if test="TestObject/Standard = '61869-2'">
					<xsl:call-template name="Excitation_Values">
						<xsl:with-param name="caller_id" select="'61869-2'" />
						<xsl:with-param name="point_node" select="$value_path/MeasPoint" />
						<xsl:with-param name="voltage_node" select="'UCTrect'" />
						<xsl:with-param name="current_node" select="'ICTrms'" />
					</xsl:call-template>		
				</xsl:if>
				<!-- C57.13 (ANSI) -->
				<xsl:if test="starts-with($standard,'ANSI') ">
					<xsl:call-template name="Excitation_Values">
						<xsl:with-param name="caller_id" select="'C57.13'" />
						<xsl:with-param name="point_node" select="$value_path/MeasPoint" />
						<xsl:with-param name="voltage_node" select="'UCorerms'" />
						<xsl:with-param name="current_node" select="'ICTrms'" />
					</xsl:call-template>		
				</xsl:if>

			</table>
		</xsl:if>
	</xsl:template>

	<!-- Printing the values (body) of the excitation table -->
	<xsl:template name="Excitation_Values">
		<xsl:param name="caller_id" />
		<xsl:param name="point_node" />
		<xsl:param name="voltage_node" />
		<xsl:param name="current_node" />

		<xsl:for-each select="$point_node">
			<tbody>
				<tr>
					<td class="decimalValue">
						<xsl:value-of select="*[name()=$voltage_node]/Displ" />
					</td>
					<td class="decimalValue">
						<xsl:value-of select="*[name()=$current_node]/Displ" />
					</td>
					<td class="decimalValue">
						<xsl:value-of select="L/Displ" />
					</td>
					<!--<td class="decimalValue">
						<xsl:value-of select="$caller_id" />
					</td>-->
				</tr>
			</tbody>
		</xsl:for-each>
	</xsl:template>

	<!-- +++++ Draws the Excitation Curve -->
	<!-- The active-X control XY-Chart is needed -->
	<xsl:template name="Chart_Excitation_Curve">
		<object id="XYGraph" classid="clsid:41483938-A58C-11D4-8244-00104B6552C4" width="400" height="350" standby="Downloading the XYGraph   control.  Please Wait!">
			<p rid="CARD_GENERAL_040">Browser does not support graphics object!</p>
			<param name="_cx" value="100000" />
			<param name="_cy" value="100000" />
			<param name="AxisLabelFontSize" value="10" />
			<param name="TickLabelFontSize" value="9" />
			<param name="MarkerSize" value="4" />
			<param name="MarkerLineWidth" value="1" />
			<param name="CurveColor" value="8421504" />
			<param name="XLabel" value="I/A" />
			<param name="YLabel" value="V/V" />
			<param name="ShowCursor" value="0" />
			<param name="ShowMarkers" value="0" />
			<param name="ShowCurve" value="1" />
			<xsl:choose>
				<xsl:when test="Tests/Cards/Excitation/Measurements//MeasPoints/Imin/Val &gt; '0'">
					<param name="XMin" value="{Tests/Cards/Excitation/Measurements/MeasPoints/Imin/Val}" />
					<param name="YMin" value="{Tests/Cards/Excitation/Measurements/MeasPoints/Umin/Val}" />
				</xsl:when>
				<xsl:otherwise>
					<param name="XMin" value="0.0001" />
					<param name="YMin" value="1.0" />
				</xsl:otherwise>
			</xsl:choose>
			<param name="XMax" value="{Tests/Cards/Excitation/Measurements/MeasPoints/Imax/Val}" />
			<param name="YMax" value="{Tests/Cards/Excitation/Measurements/MeasPoints/Umax/Val}" />
			<xsl:choose>
				<xsl:when test="TestObject/Standard = '60044-1'">
					<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/IEC_1/I/Val &gt; '0'">
						<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/IEC_1/U/Val &gt; '0'">
							<param name="XIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/IEC_1/I/Val}" />
							<param name="YIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/IEC_1/U/Val}" />
							<param name="ShowIndicator" value="1" />
						</xsl:if>
					</xsl:if>
				</xsl:when>
				<xsl:when test="TestObject/Standard = '60044-6'">
					<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/IEC_6/I/Val &gt; '0'">
						<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/IEC_6/U/Val &gt; '0'">
							<param name="XIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/IEC_6/I/Val}" />
							<param name="YIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/IEC_6/U/Val}" />
							<param name="ShowIndicator" value="1" />
						</xsl:if>
					</xsl:if>
				</xsl:when>
				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/IEC_69_2/I/Val &gt; '0'">
						<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/IEC_69_2/U/Val &gt; '0'">
							<param name="XIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/IEC_69_2/I/Val}" />
							<param name="YIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/IEC_69_2/U/Val}" />
							<param name="ShowIndicator" value="1" />
						</xsl:if>
					</xsl:if>
				</xsl:when>
				<xsl:when test="TestObject/Standard = 'ANSI 30'">
					<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/ANSI_30/I/Val &gt; '0'">
						<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/ANSI_30/U/Val &gt; '0'">
							<param name="XIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/ANSI_30/I/Val}" />
							<param name="YIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/ANSI_30/U/Val}" />
							<param name="ShowIndicator" value="1" />
						</xsl:if>
					</xsl:if>
				</xsl:when>
				<xsl:when test="TestObject/Standard='ANSI 45' or TestObject/Standard='C57.13'">
					<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/ANSI_45/I/Val &gt; '0'">
						<xsl:if test="Tests/Cards/Excitation/Measurements/KneePoints/ANSI_45/U/Val &gt; '0'">
							<param name="XIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/ANSI_45/I/Val}" />
							<param name="YIndicator" value="{Tests/Cards/Excitation/Measurements/KneePoints/ANSI_45/U/Val}" />
							<param name="ShowIndicator" value="1" />
						</xsl:if>
					</xsl:if>
				</xsl:when>
			</xsl:choose>
			<param name="ValuesCount" value="{Tests/Cards/Excitation/Measurements//MeasPoints/NumPoints}" />

			<xsl:choose>
				<xsl:when test="TestObject/Standard = '60044-1'">
					<xsl:for-each select="Tests/Cards/Excitation/Measurements/MeasPoints/MeasPoint">
						<param name="XValue{position()}" value="{ICTrms/Val}" />
						<param name="YValue{position()}" value="{UCTrms/Val}" />
					</xsl:for-each>
				</xsl:when>

				<xsl:when test="TestObject/Standard = '60044-6'">
					<xsl:for-each select="Tests/Cards/Excitation/Measurements/MeasPoints/MeasPoint">
						<param name="XValue{position()}" value="{ICTpeak/Val}" />
						<param name="YValue{position()}" value="{UCorerms/Val}" />
					</xsl:for-each>
				</xsl:when>

				<xsl:when test="TestObject/Standard = '61869-2'">
					<xsl:for-each select="Tests/Cards/Excitation/Measurements/MeasPoints/MeasPoint">
						<param name="XValue{position()}" value="{ICTrms/Val}" />
						<param name="YValue{position()}" value="{UCTrect/Val}" />
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="Tests/Cards/Excitation/Measurements/MeasPoints/MeasPoint">
						<param name="XValue{position()}" value="{ICTrms/Val}" />
						<param name="YValue{position()}" value="{UCorerms/Val}" />
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>

		</object>
	</xsl:template>




	<xsl:template name="K_Error_Graph">
		<xsl:param name="ExcitationCard" />

		<!-- K-Value Error Graph begin -->
		<xsl:if test="$ExcitationCard/Measurements/ALError/Enable = 1 and $ExcitationCard/Measurements/ALError/NumPoints &gt; 0">
			<h2 style="page-break-before: always" rid="CARD_EXCITATION_113">Accuracy limiting graph:</h2>
			<div class="dataBlockEnd" name="Excitation_accuracy_limit_graph">
				<table>
					<tr>
						<td class="descriptor" rid="CARD_EXCITATION_114">Error:</td>
						<td>
							<xsl:value-of select="$ExcitationCard/Measurements/ALError/Error" />%
						</td>
					</tr>
					<tr>
						<td class="descriptor" rid="CARD_EXCITATION_117">K-factor at rated burden:</td>
						<td>
							<xsl:value-of select="$ExcitationCard/Measurements/ALError/NomBurden/KValue" />
						</td>
					</tr>
					<tr>
						<td class="descriptor" rid="CARD_EXCITATION_118">K-factor at operating burden:</td>
						<td>
							<xsl:value-of select="$ExcitationCard/Measurements/ALError/OprBurden/KValue" />
						</td>
					</tr>
				</table>

				<table>
					<tr>
						<td>
							<table class="valueTable">
								<thead>
									<tr>
										<th align="center" rid="CARD_EXCITATION_115">K-Value</th>
										<th align="center" rid="CARD_EXCITATION_116">Impedance [&#8486;]</th>
									</tr>
								</thead>
								<tbody>
									<xsl:for-each select="$ExcitationCard/Measurements/ALError/MeasPoint">
										<tr>
											<td class="decimalValue">
												<xsl:value-of select="format-number(KValue,'#0.00')" />
											</td>
											<td  class="decimalValue">
												<xsl:value-of select="format-number(Impedance,'#0.000')" />
											</td>
										</tr>
									</xsl:for-each>
								</tbody>
							</table>
						</td>
						<td>
							<!-- draw k-value error graph-->
							<xsl:call-template name="Chart_Excitation_K_Value_Error_Graph"/>
						</td>
					</tr>
				</table>

			</div>
		</xsl:if>
		<!-- K-Value Error Graph end -->
	</xsl:template>

	<!-- +++++ Draws the k value error Curve -->
	<xsl:template name="Chart_Excitation_K_Value_Error_Graph">
		<object id="XYGraph" classid="clsid:41483938-A58C-11D4-8244-00104B6552C4" width="400" height="350" standby="Downloading the XYGraph 	control. 	Please Wait!">
			<p rid="CARD_GENERAL_040">Browser does not support graphics object!</p>
			<param name="_cx" value="100000" />
			<param name="_cy" value="100000" />
			<param name="AxisLabelFontSize" value="10" />
			<param name="TickLabelFontSize" value="9" />
			<param name="MarkerSize" value="4" />
			<param name="MarkerLineWidth" value="1" />
			<param name="CurveColor" value="8421504" />
			<param name="ShowCursor" value="0" />
			<param name="ShowMarkers" value="0" />
			<param name="ShowCurve" value="1" />
			<param name="XLabel" value="Z/Ohm" />
			<param name="XMin" value="0" />
			<param name="XMax" value="{Tests/Cards/Excitation/Measurements/ALError/Rmax}" />
			<param name="XLogarithmic" value="0" />
			<param name="YLabel" value="K-Value" />
			<param name="YMin" value="0" />
			<param name="YMax" value="{Tests/Cards/Excitation/Measurements/ALError/Kmax}" />
			<param name="YLogarithmic" value="0" />
			<param name="XIndicator" value="{Tests/Cards/Excitation/Measurements/ALError/NomBurden/Impedance}" />
			<param name="YIndicator" value="{Tests/Cards/Excitation/Measurements/ALError/NomBurden/KValue}" />
			<param name="ShowIndicator" value="1" />
			<param name="ValuesCount" value="{Tests/Cards/Excitation/Measurements/ALError/NumPoints}" />
			<xsl:for-each select="Tests/Cards/Excitation/Measurements/ALError/MeasPoint">
				<param name="XValue{position()}" value="{Impedance}" />
				<param name="YValue{position()}" value="{KValue}" />
			</xsl:for-each>
		</object>

	</xsl:template>



	<!--  *****    Card Ratio Value Templates   *****  -->


	<!--This template will show the accuracy tables (up to version 4.05)-->
	<!--The tables will show burden values for 100%, 50%, 25%, 12.5% accoring to IEC 60044-->
	<!--The same scheme is also used to display C57.13 tables. to see the 
	designated burden values incl. assessment indicator please use the new table for the extended accuracy table-->
	<xsl:template name="Ratio_Accuracy_Tables">
		<xsl:param name="RatioCard"/>
		<div class="dataBlockEnd" name="Ratio_nominal_burden">
			<table>
				<tr>

				</tr>
				<tr>
					<td>
						<table class="valueTable">
							<xsl:variable name="valueCount" select="count($RatioCard/Measurements/Accuracy/CurrentTable/RatedCurrent)" />
							<thead>
								<tr>
									<th align="center" rid="CARD_RATIO_011">Burden</th>
									<th align="center" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount" />
										</xsl:attribute>
										<IDTag  rid="CARD_RATIO_012">Current ratio error in % at % of rated current</IDTag>
									</th>
								</tr>

								<tr>
									<th align="center" rid="CARD_RATIO_013">VA /&#160;<span>cos &#966;</span>&#160;</th>

									<xsl:for-each select="$RatioCard/Measurements/Accuracy/CurrentTable/RatedCurrent">
										<th align="center">
											<xsl:value-of select="Displ" /> %
										</th>
									</xsl:for-each>
								</tr>
							</thead>
							<tbody>
								<!-- for each burden value -->
								<xsl:for-each select="$RatioCard/Measurements/Accuracy/PowerTable/Power">

									<!-- remember the the burden value to write the value later in the table -->
									<xsl:variable name="burdenValue">

										<!--<xsl:value-of select="Power/Displ" /> / <xsl:value-of select="CosPhi/Displ" />-->
										<xsl:value-of select="format-number(Power/Val,'#0.00#')" /> / <xsl:value-of select="format-number(CosPhi/Val,'#0.0')" />
									</xsl:variable>

									<!-- find the index of the actual burden value to read the corresponding ration and phase tables-->
									<xsl:variable name="positionCounter" select="position()" />

									<!-- for each corresponding phase table -->
									<xsl:for-each select="../../RatioTable[$positionCounter]">
										<tr>
											<td  class="decimalValue">
												<xsl:value-of select="$burdenValue" />
											</td>
											<xsl:for-each select="CurrentRatioError">
												<td class="decimalValue">
													<xsl:if test="Qualifier = '1'">! </xsl:if>
													<xsl:value-of select="Displ" />
												</td>
											</xsl:for-each>
										</tr>
									</xsl:for-each>
								</xsl:for-each>
								<tr>
									<td class="tableDivider" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount+1" />
										</xsl:attribute>
												&#160; </td>
								</tr>
							</tbody>

							<thead>
								<tr>
									<th align="center" rid="CARD_RATIO_014">Burden</th>
									<th align="center" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount" />
										</xsl:attribute>
										<IDTag  rid="CARD_RATIO_015">Phase displacement in minutes at % of rated current</IDTag>
									</th>
								</tr>

								<tr>
									<th align="center" rid="CARD_RATIO_016">VA /&#160;<span>cos &#966;</span>&#160;</th>

									<xsl:for-each select="$RatioCard/Measurements/Accuracy/CurrentTable/RatedCurrent">
										<th align="center">
											<xsl:value-of select="Displ" /> %
										</th>
									</xsl:for-each>
								</tr>
							</thead>
							<tbody>
								<!-- for each burden value -->
								<xsl:for-each select="$RatioCard/Measurements/Accuracy/PowerTable/Power">

									<!-- remember the the burden value to write the value later in the table -->
									<xsl:variable name="burdenValue">
										<!--<xsl:value-of select="Power/Displ" /> / <xsl:value-of select="CosPhi/Displ" />-->
										<xsl:value-of select="format-number(Power/Val,'#0.00#')" /> / <xsl:value-of select="format-number(CosPhi/Val,'#0.0')" />
									</xsl:variable>

									<!-- find the index of the actual burden value to read the corresponding ration and phase tables-->
									<xsl:variable name="positionCounter" select="position()" />

									<!-- for each corresponding phase table -->
									<xsl:for-each select="../../PhaseTable[$positionCounter]">
										<tr>
											<td class="decimalValue">
												<xsl:value-of select="$burdenValue" />
											</td>
											<xsl:for-each select="PhaseDisplacement">
												<td class="decimalValue">
													<xsl:if test="Qualifier = '1'">! </xsl:if>
													<xsl:value-of select="Displ" />
												</td>
											</xsl:for-each>
										</tr>
									</xsl:for-each>
								</xsl:for-each>

								<tr>
									<td class="tableDivider" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount + 1" />
										</xsl:attribute>
												&#160; </td>
								</tr>

								<tr>
									<td align="left" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount + 1" />
										</xsl:attribute>
										<IDTag rid="CARD_RATIO_NOTE">NOTE: Measurements with '!' have reduced accuracy. Accuracy only guaranteed on non-gapped cores.</IDTag>
									</td>
								</tr>

							</tbody>
						</table>

					</td>
				</tr>
			</table>
		</div>

	</xsl:template>


	<!--This template will show the extended accuracy table (implemented in CTA 4.10)-->
	<!--This includes burden designations for C57.13 CTs and assessment indicators-->
	<xsl:template name="Ratio_Extended_Accuracy_Tables">
		<xsl:param name="RatioCard"/>

		<div class="dataBlockEnd" name="Ratio_nominal_burden">
			<table>
				<tr>

				</tr>
				<tr>
					<td>
						<table class="valueTable">
							<xsl:variable name="valueCount" select="count($RatioCard/Measurements/AccuracyNomBurden/CurrentTable/RatedCurrent)" />
							<!--Current Ratio Table-->
							<thead>
								<tr>
									<th align="center" rid="CARD_RATIO_011">Burden</th>
									<th align="center" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount" />
										</xsl:attribute>
										<IDTag  rid="CARD_RATIO_012">Current ratio error in % at % of rated current</IDTag>
									</th>
									<th align="center" rid="Card_RATIO_020">Designation</th>
								</tr>

								<tr>
									<th align="center" rid="CARD_RATIO_013">VA /&#160;<span>cos &#966;</span>&#160;</th>

									<xsl:for-each select="$RatioCard/Measurements/AccuracyNomBurden/CurrentTable/RatedCurrent">
										<th align="center">
											<xsl:value-of select="Displ" /> %
										</th>
									</xsl:for-each>
									<th/>
								</tr>
							</thead>
							<tbody>
								<!-- for each burden value -->
								<xsl:for-each select="$RatioCard/Measurements/AccuracyNomBurden/PowerTable/Power">

									<!-- remember the the burden value to write the value later in the table -->
									<xsl:variable name="burdenValue">
										<xsl:value-of select="format-number(Power/Val,'#0.00#')" /> / <xsl:value-of select="format-number(CosPhi/Val,'#0.0')" />
									</xsl:variable>

									<!-- remember the the burden designation to write the value later in the table -->
									<xsl:variable name="burdenDesignation">
										<xsl:value-of select="Power/Designation" />
									</xsl:variable>

									<!-- find the index of the actual burden value to read the corresponding ration and phase tables-->
									<xsl:variable name="positionCounter" select="position()" />

									<!-- for each corresponding phase table -->
									<xsl:for-each select="../../RatioTable[$positionCounter]">
										<tr>
											<td  class="decimalValue">
												<xsl:value-of select="$burdenValue" />
											</td>
											<!--for each ratio error in the row-->
											<xsl:for-each select="CurrentRatioError">
												<td class="decimalValue">
													<xsl:if test="Qualifier = '1'">! </xsl:if>
													<xsl:value-of select="Displ" />
													<!--indicate failed assessment-->
													<xsl:if test="Assess = '-1'">
														(<IDTag rid="CARD_ASS_055">Failed</IDTag>)
													</xsl:if>
												</td>
											</xsl:for-each>
											<td align="center">
												<xsl:value-of select="$burdenDesignation" />
											</td>
										</tr>
									</xsl:for-each>
								</xsl:for-each>
								<tr>
									<td class="tableDivider" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount+1" />
										</xsl:attribute>
												&#160; </td>
								</tr>
							</tbody>

							<!--Current Phase Table-->
							<thead>
								<tr>
									<th align="center" rid="CARD_RATIO_014">Burden</th>
									<th align="center" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount" />
										</xsl:attribute>
										<IDTag  rid="CARD_RATIO_015">Phase displacement in minutes at % of rated current</IDTag>
									</th>
									<th align="center" rid="Card_RATIO_020">Designation</th>
								</tr>

								<tr>
									<th align="center" rid="CARD_RATIO_016">VA /&#160;<span>cos &#966;</span>&#160;</th>

									<xsl:for-each select="$RatioCard/Measurements/AccuracyNomBurden/CurrentTable/RatedCurrent">
										<th align="center">
											<xsl:value-of select="Displ" /> %
										</th>
									</xsl:for-each>
									<th/>
								</tr>
							</thead>
							<tbody>
								<!-- for each burden value -->
								<xsl:for-each select="$RatioCard/Measurements/AccuracyNomBurden/PowerTable/Power">

									<!-- remember the the burden value to write the value later in the table -->
									<xsl:variable name="burdenValue">
										<xsl:value-of select="format-number(Power/Val,'#0.00#')" /> / <xsl:value-of select="format-number(CosPhi/Val,'#0.0')" />
									</xsl:variable>

									<!-- remember the the burden designation to write the value later in the table -->
									<xsl:variable name="burdenDesignation">
										<xsl:value-of select="Power/Designation" />
									</xsl:variable>

									<!-- find the index of the actual burden value to read the corresponding ration and phase tables-->
									<xsl:variable name="positionCounter" select="position()" />

									<!-- for each corresponding phase table -->
									<xsl:for-each select="../../PhaseTable[$positionCounter]">
										<tr>
											<td class="decimalValue">
												<xsl:value-of select="$burdenValue" />
											</td>
											<xsl:for-each select="PhaseDisplacement">
												<td class="decimalValue">
													<xsl:if test="Qualifier = '1'">! </xsl:if>
													<xsl:value-of select="Displ" />
													<!--indicate failed assessment-->
													<xsl:if test="Assess = '-1'">
																(<IDTag rid="CARD_ASS_055">Failed</IDTag>)
													</xsl:if>
												</td>
											</xsl:for-each>
											<td align="center">
												<xsl:value-of select="$burdenDesignation" />
											</td>
										</tr>
									</xsl:for-each>
								</xsl:for-each>

								<tr>
									<td class="tableDivider" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount + 1" />
										</xsl:attribute>
												&#160; </td>
								</tr>

								<tr>
									<td align="left" colspan="100%">
										<xsl:attribute name="colspan">
											<xsl:value-of select="$valueCount + 1" />
										</xsl:attribute>
										<IDTag rid="CARD_RATIO_NOTE">NOTE: Measurements with '!' have reduced accuracy. Accuracy only guaranteed on non-gapped cores.</IDTag>
									</td>
								</tr>

							</tbody>
						</table>

					</td>
				</tr>
			</table>
		</div>
	</xsl:template>

</xsl:stylesheet>
