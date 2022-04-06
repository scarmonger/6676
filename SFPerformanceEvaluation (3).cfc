	<cfcomponent name="SFPerformanceEvaluation" hint="SunFish Performance Evaluation Object" extends="SFBP">
		<cfsetting showdebugoutput="yes">
	    <cfset strckArgument = {
								"Module" 			= "PM",
								"ObjectName" 		= "PerformanceEvaluation-",
								"ObjectTable" 		= "TPMDPERFORMANCE_EVALH",
								"ObjectTitle" 		= "Performance Evaluation",
								"KeyField" 			= "request_no",
								"TitleField" 		= "Request No",
								"GridColumn" 		= "", <!--- defined on Listing method --->
								"PKeyField" 		= "",
								"ObjectApproval" 	= "PERFORMANCE.Evaluation",
								"DocApproval" 		= "PERFORMANCEEVALUATION",
								"bIsTransaction" 	= true
							} />
		<cfif not IsDefined("REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE")>
			<cfset REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE = 0>
		
		</cfif>
		<cfset Init(argumentCollection = strckArgument) />
    		
    	<!---TCK2002-0548467--->
        <Cfset REQUEST.InitVarCountDeC = getDecimalCountFromParam()>
        <cffunction name="getDecimalCountFromParam">
            <cfset LOCAL.VarNumFormatConf = request.config.NUMERIC_FORMAT>
            <cfset LOCAL.VargetDecimalAfter = ListLast(VarNumFormatConf,'.')>
            <cfset LOCAL.InitVarCountDeC = LEN(VargetDecimalAfter)> 
            
            <cfreturn InitVarCountDeC>
        </cffunction>
        <!---TCK2002-0548467--->
		<cffunction name="getEmpListing">
				<cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"yyyy-mm-dd")>
				<cfparam name="inp_startdt" default="#nowdate#">
				<cfparam name="inp_enddt" default="#nowdate#">
				<cfparam name="ReturnVarCheckCompParam" default="1">
				<cfquery name="local.qPeriodPerfEval" datasource="#request.sdsn#">
					select period_code from tpmmperiod where final_enddate >= '#inp_startdt#' AND final_startdate <= '#inp_enddt#' and company_code = '#REQUEST.SCOOKIE.COCODE#'
				</cfquery>
			    
		    	<cfif ReturnVarCheckCompParam eq true>
					 <cfquery name="local.qGetEmp" datasource="#request.sdsn#">
						 SELECT reviewee_empid emp_id, 
						  period_code 
						FROM 
						  TPMDPERFORMANCE_EVALGEN EH 
						WHERE 
						  company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> 
						  AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
                            <cfif qPeriodPerfEval.recordcount gt 0 and qPeriodPerfEval.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriodPerfEval.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                            </cfif>
						GROUP BY reviewee_empid, period_code
						UNION 
						SELECT EC.emp_id, EH.period_code 
						FROM 
						  TCLTREQUEST REQ LEFT JOIN TEODEMPCOMPANY EC ON ( EC.emp_id = REQ.reqemp  AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> )
						 
						  LEFT JOIN TPMDPERFORMANCE_EVALH EH ON EH.reviewee_empid = REQ.reqemp 
						  AND EH.request_no = REQ.req_no 
						 
						WHERE 
						  UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION' 
						  AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						  AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriodPerfEval.recordcount gt 0 and qPeriodPerfEval.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriodPerfEval.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
						GROUP BY emp_id, period_code
					</cfquery>
					
				<cfelse>
					<cfquery name="local.qGetEmp" datasource="#request.sdsn#">
					SELECT DISTINCT EC.emp_id,EH.period_code	FROM TCLTREQUEST REQ
					LEFT JOIN TPMDPERFORMANCE_EVALH EH
						ON  EH.reviewee_empid = REQ.reqemp 
						AND EH.request_no = REQ.req_no
					LEFT JOIN TEODEMPCOMPANY EC ON EC.emp_id = REQ.reqemp
						AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					WHERE UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION'
						AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriodPerfEval.recordcount gt 0 and qPeriodPerfEval.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriodPerfEval.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
					</cfquery>
				</cfif>
				<cfreturn qGetEmp>
		</cffunction>
		<cffunction name="isGeneratePrereviewer">
			<cfset local.retvarCompParam = false>
			<cfquery name="LOCAL.qGetCompParam" datasource="#REQUEST.SDSN#">
			select field_value from tclcappcompany where UPPER(module) = 'PERFORMANCE' and UPPER(field_code) = 'PREGENERATE_REVIEWER'
			and company_id = #REQUEST.SCOOKIE.COID#
			</cfquery>
			<cfif qGetCompParam.field_value neq "">
				<cfif UCASE(qGetCompParam.field_value) eq "Y">
					<cfset retvarCompParam = true>
				</cfif>
			</cfif>
			<cfreturn retvarCompParam>
		</cffunction>
		
		<cfset variables.objPerfEvalH = CreateObject("component","SMPerfEvalH")/>
		<cfset variables.objPerfEvalD = CreateObject("component","SMPerfEvalD")/>
		<cfset variables.objRequestApproval = CreateObject("component","SFRequestApproval").init(false) /><!---TCK1908-0518296 set ke false untuk skip approver ketika step workflow approval tidak ditemukan employeenya--->
		<cfset variables.company_code = REQUEST.SCOOKIE.COCODE>
	
	<cffunction name="qGetListPlanFullyApproveAndClosed">
		<cfparam name="period_code" default="">
		<cfparam name="lst_emp_id" default="">
		<cfparam name="is_emp_defined" default="N">
		<cfparam name="by_form_no" default="N">
		<cfparam name="form_no" default="">
		<cfparam name="isfinal" default="1">
		
		<cfparam name="allstatus" default="false"><!--- TCK1018-81902 --->
		
		<!--- Get emp_id fully approved perf plan--->
		<cfquery name="local.qListEmpFullyApprClosed" datasource="#request.sdsn#">
            SELECT 	DISTINCT 	TPMDPERFORMANCE_EVALH.form_no, 
            	TPMDPERFORMANCE_EVALH.period_code,
            	TPMDPERFORMANCE_EVALH.reviewee_empid,
            	TPMDPERFORMANCE_EVALH.reference_date
            	
            	,TCLTREQUEST.reqemp
            	,TEOMEMPPERSONAL.full_name
            	,TEODEMPCOMPANY.emp_no
            	
            	,TEOMPOSITION.pos_name_#request.scookie.lang# AS pos_name
				,ORG.position_id as orgunitid
            	,ORG.pos_name_#request.scookie.lang# AS orgunit
            	,TEOMJOBGRADE.grade_name
            	
            	,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
            	,TPMDPERFORMANCE_EVALH.request_no
            	,TPMDPERFORMANCE_EVALH.reviewer_empid
            FROM TPMDPERFORMANCE_EVALH
            
            LEFT JOIN TCLTREQUEST	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_EVALH.request_no	AND TCLTREQUEST.req_no IS NOT NULL
            LEFT JOIN TEOMEMPPERSONAL	ON TEOMEMPPERSONAL.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
            LEFT JOIN TEODEMPCOMPANY  ON TEODEMPCOMPANY.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
            LEFT JOIN TEOMPOSITION ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id 
            LEFT JOIN TEOMPOSITION ORG  ON ORG.position_id = TEOMPOSITION.dept_id
            LEFT JOIN TPMMPERIOD  ON TPMMPERIOD.period_code = TPMDPERFORMANCE_EVALH.period_code      
            LEFT JOIN TEOMJOBGRADE ON TEODEMPCOMPANY.grade_code = TEOMJOBGRADE.grade_code 
                AND TEODEMPCOMPANY.company_id = TEOMJOBGRADE.company_id 
                    	
            WHERE TCLTREQUEST.req_no IS NOT NULL
                AND TPMDPERFORMANCE_EVALH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
            
                <cfif allstatus EQ true>
					 AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                <cfelse>
	            	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
                </cfif>
            	
            	<cfif by_form_no EQ 'Y'>
            	    AND TPMDPERFORMANCE_EVALH.form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar">
            	<cfelse>
            	    AND TPMDPERFORMANCE_EVALH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
            	</cfif>
            	
            	<cfif is_emp_defined eq 'Y' AND lst_emp_id neq ''>
            	    AND TPMDPERFORMANCE_EVALH.reviewee_empid IN (<cfqueryparam value="#lst_emp_id#" cfsqltype="cf_sql_varchar" list="yes">)
            	</cfif>
            	<cfif isfinal eq 1>
            	    AND TPMDPERFORMANCE_EVALH.isfinal = 1
            	</cfif>
            	
            ORDER BY TEOMEMPPERSONAL.full_name
		</cfquery>
		
		<cfreturn qListEmpFullyApprClosed>

	</cffunction>
	
	<cffunction name="DeletePlan">
	    <cfparam name="lstdelete" default="">
		<cfset LOCAL.ObjPlanning = createobject("component","SFPerformancePlanning")>
		
		<cfquery name="local.qListEmpFullyApprClosed" datasource="#request.sdsn#">
		    select form_no ,file_attachment from TPMDPERF_EVALATTACHMENT
		    where form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar">
		    and company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
		    
		</cfquery>
		
	    <cfloop list="#lstdelete#" index="LOCAL.form_no">
	        <cfset LOCAL.retVarDeleteByFormNo = ObjPlanning.DeleteAllPerfPlanByFormNo(form_no=form_no)>
	    </cfloop>
	    
        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSYou have successfully delete Performance Evaluation data",true)>
		<cfif retVarDeleteByFormNo eq false>
		    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Delete Performance Evaluation Form",true)>
		</cfif>
	    
		<cfoutput>
			<script>
				alert("#SFLANG#");
				top.popClose();
				if(top.opener){
					top.opener.reloadPage();
				}
			</script>
		</cfoutput>
	</cffunction>

		
		<cffunction name="Listing">
				<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
					<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
				<cfelse>
					<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
				</cfif>
				
				<cfset local.sdate = DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),1),"yyyy-mm-dd")>
				<cfset local.edate = DATEFORMAT(CreateDate(Datepart("yyyy",now()),12,31),"#REQUEST.CONFIG.DATE_INPUT_FORMAT#")>
				<cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"yyyy-mm-dd")>
				<cfparam name="inp_startdt" default="#nowdate#">
				<cfparam name="inp_enddt" default="#nowdate#">
				
				<cfset inp_startdt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_startdt),Datepart("m",inp_startdt),Datepart("d",inp_startdt)),"yyyy-mm-dd")>
				<cfset inp_enddt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_enddt),Datepart("m",inp_enddt),Datepart("d",inp_enddt)),"yyyy-mm-dd")>
				
				<cfset LOCAL.scParam=paramRequest()>
					<cfset Local.StrckTemp = listingFilter(inp_startdt=inp_startdt,inp_enddt=inp_enddt)>
			        <cfif ReturnVarCheckCompParam eq true>
					    <cfif request.dbdriver eq "MSSQL">
                             <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p  INNER JOIN tpmrperiodfilterjflcode aa ON aa.period_code = p.period_code WHERE aa.company_code = '#request.scookie.cocode#') THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( ( p.final_startdate <= '#inp_enddt#' AND p.final_enddate >= '#inp_startdt#' ) AND p.period_code IN ( SELECT period_code FROM tpmrperiodfilteremploycode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( ( p.final_startdate <= '#inp_enddt#' AND p.final_enddate >= '#inp_startdt#' ) AND p.period_code IN ( SELECT  period_code FROM tpmrperiodfilterjobstatuscode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date,CONVERT (VARCHAR(10),PER.reference_date,120) AS refdate, ( SELECT TOP 1 req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalgen eh ON eh.req_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC  ) AS reqno, CASE WHEN ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req left JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC ) IS NULL THEN 'Unverified' ELSE ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC ) END AS reqstatus, ( SELECT TOP 1 eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC  ) AS isfinal, ( SELECT TOP 1 eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC ) AS modified_date, ( SELECT TOP 1 eh.form_no FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code  and eh.reviewee_posid = E.position_id AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC ) AS formno, ( SELECT TOP 1 eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS score1, ( select TOP 1 p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id order by eh.MODIFIED_DATE desc  ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT TOP 1 ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ) AS final_conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ) AS conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 AND len(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC ) AS score, ( SELECT TOP 1 CASE WHEN ph.form_no is not null THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_evalgen ph ON ph.req_no = plr.req_no AND plr.req_type = 'PERFORMANCE.EVALUATION'  AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id and ph.reviewee_posid = E.position_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC ) AS planformno, ( SELECT TOP 1 plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.reviewee_posid = E.position_id AND ph.period_code = per.period_code  ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT TOP 1 eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC  ) AS score2, ( SELECT TOP 1 eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC  ) AS reviewer_empid, ( SELECT TOP 1 round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = e.position_id  ORDER BY eh2.modified_date DESC ) AS loginscore, ( SELECT TOP 1 eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = e.position_id ORDER BY eh2.modified_date DESC ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id AND b.reviewee_posid = e.position_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id AND b.reviewee_posid = e.position_id  ) AS max_modified_date">
                        <cfelse>
			                <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( ( p.final_startdate <= '#inp_enddt#' AND p.final_enddate >= '#inp_startdt#' ) AND p.period_code IN ( SELECT DISTINCT period_code FROM tpmrperiodfilterjflcode ) ) ) THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( ( p.final_startdate <= '#inp_enddt#' AND p.final_enddate >= '#inp_startdt#' ) AND p.period_code IN ( SELECT period_code FROM tpmrperiodfilteremploycode group by period_code ) ) ) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( ( p.final_startdate <= '#inp_enddt#' AND p.final_enddate >= '#inp_startdt#' ) AND p.period_code IN ( SELECT  period_code FROM tpmrperiodfilterjobstatuscode group by period_code ) ) ) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date, CONVERT ( per.reference_date, char(10) ) AS refdate, ( SELECT req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalgen eh ON eh.req_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code and eh.reviewee_posid = E.position_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) AS reqno, CASE WHEN ( SELECT CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC limit 1 ) IS NULL THEN 'Unverified' ELSE ( SELECT CASE WHEN req.req_no IS NOT NULL and eh.head_status = 1 THEN reqsts.name_#request.scookie.lang# ELSE CASE WHEN req.req_no IS NOT NULL and eh.head_status = 0 THEN 'Draft' ELSE 'Not Requested' END END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC limit 1 ) END AS reqstatus, ( SELECT eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS isfinal, ( SELECT eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code and eh.reviewee_posid = E.position_id ORDER BY eh.modified_date DESC limit 1 ) AS modified_date, ( SELECT eh.form_no FROM tpmdperformance_evalgen eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code  and eh.reviewee_posid = E.position_id AND eh.company_id = #request.scookie.coid# ORDER BY eh.modified_date DESC limit 1 ) AS formno, ( SELECT eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code and eh.reviewee_posid = E.position_id  ORDER BY eh.modified_date DESC limit 1 ) AS score1, ( select p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id  order by eh.MODIFIED_DATE desc limit 1 ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code and eh.reviewee_posid = E.position_id limit 1 ) AS final_conclusion, ( SELECT CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id AND eh.period_code = per.period_code limit 1 ) AS conclusion, ( SELECT CASE WHEN eh.isfinal = 1 AND length(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) AS score, ( SELECT CASE WHEN ph.form_no is not null THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_evalgen ph ON ph.req_no = plr.req_no AND plr.req_type = 'PERFORMANCE.EVALUATION'  AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id and ph.reviewee_posid = E.position_id  AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planformno, ( SELECT plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.reviewee_posid = E.position_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS score2, ( SELECT eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS reviewer_empid, ( SELECT round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginscore, ( SELECT eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id  AND eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id AND b.reviewee_posid = E.position_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id AND b.reviewee_posid = E.position_id ) AS max_modified_date">
			               
				        </cfif>
				    <cfelse>
                        <cfif request.dbdriver eq "MSSQL">
                              <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p INNER JOIN tpmrperiodfilterjflcode aa ON aa.period_code = p.period_code WHERE aa.company_code = '#request.scookie.cocode#') THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( ( p.final_startdate <= '#inp_enddt#' AND p.final_enddate >= '#inp_startdt#' ) AND p.period_code IN ( SELECT period_code FROM tpmrperiodfilteremploycode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN ( SELECT p.period_code FROM tpmmperiod p WHERE ( ( p.final_startdate <= '#inp_enddt#' AND p.final_enddate >= '#inp_startdt#' ) AND p.period_code IN ( SELECT  period_code FROM tpmrperiodfilterjobstatuscode WHERE company_code = '#request.scookie.cocode#' group by period_code ) ) ) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date,CONVERT (VARCHAR(10),PER.reference_date,120) AS refdate, ( SELECT TOP 1 req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.reviewee_posid = E.position_id and eh.period_code = per.period_code ORDER BY eh.modified_date DESC  ) AS reqno, CASE WHEN (  SELECT  TOP 1 CASE  WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang#   ELSE   'Not Requested'  END  reqstatus FROM tcltrequest req  INNER JOIN  tpmdperformance_evalh eh   ON eh.request_no = req.req_no  AND req.req_type = 'PERFORMANCE.EVALUATION'   INNER JOIN tgemreqstatus reqsts   ON req.status = reqsts.code  WHERE  req.reqemp = e.emp_id    AND req.reqemp = e.emp_id    AND req.company_id = #REQUEST.SCOOKIE.COID#    AND req.reqemp = eh.reviewee_empid   AND eh.period_code = per.period_code    and eh.reviewee_posid = E.position_id  AND EH.head_status = 0   AND EH.lastreviewer_empid = '#request.scookie.user.empid#'     ORDER BY  eh.modified_date DESC   )    IS NOT NULL  THEN    'Draft'  ELSE CASE WHEN ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id  ORDER BY eh.modified_date DESC ) IS NULL THEN 'Not Requested' ELSE ( SELECT TOP 1 CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id  ORDER BY eh.modified_date DESC ) END END AS reqstatus, ( SELECT TOP 1 eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id  AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS isfinal, ( SELECT TOP 1 eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id  AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC ) AS modified_date, ( SELECT TOP 1 eh.form_no FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id  AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS formno, ( SELECT TOP 1 eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id  AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC  ) AS score1, ( select TOP 1 p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id  order by eh.MODIFIED_DATE desc  ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT TOP 1 ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id AND eh.company_code = per.company_code ) AS final_conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.period_code = per.period_code and eh.reviewee_posid = E.position_id ) AS conclusion, ( SELECT TOP 1 CASE WHEN eh.isfinal = 1 AND len(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id and eh.reviewee_posid = E.position_id AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC ) AS score, ( SELECT TOP 1 CASE WHEN plr.status IN ( 3, 9 ) THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id and ph.reviewee_posid = E.position_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC ) AS planformno, ( SELECT TOP 1 plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id and ph.reviewee_posid = E.position_id AND ph.period_code = per.period_code  ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT TOP 1 eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id and eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC ) AS score2, ( SELECT TOP 1 eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id and eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC  ) AS reviewer_empid, ( SELECT TOP 1 round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id and eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC ) AS loginscore, ( SELECT TOP 1 eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id and eh2.reviewee_posid = E.position_id ORDER BY eh2.modified_date DESC ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id and b.reviewee_posid = E.position_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id and b.reviewee_posid = E.position_id ) AS max_modified_date">
                        <cfelse>
			                <cfset LOCAL.lsField="e.company_id, p.full_name AS emp_name, e.emp_id, e.emp_no, '-' AS reqapporder, pos.pos_name_#request.scookie.lang# AS emp_pos, dep.pos_name_#request.scookie.lang# dept, pos.position_id, e.employ_code, e.job_status_code, es.employmentstatus_name_#request.scookie.lang# AS status, per.period_code AS periodcode, CASE WHEN jfl.period_code IS NULL AND per.period_code = jfl.period_code OR jfl.emp_id IS NULL AND per.period_code NOT IN (SELECT period_code FROM  tpmrperiodfilterjflcode aa WHERE aa.company_code = '#request.scookie.cocode#' )THEN '-' ELSE per.period_code END jfl_per , CASE WHEN jfl.emp_id IS NOT NULL AND jfl.emp_id = e.emp_id THEN jfl.emp_id ELSE '-' END jfl , CASE WHEN fec.period_code IS NULL AND per.period_code = fec.period_code OR fec.employmentstatus_code IS NULL AND per.period_code NOT IN (SELECT cc.period_code FROM tpmrperiodfilteremploycode cc WHERE cc.company_code='#request.scookie.cocode#' group by period_code) THEN '-' ELSE per.period_code END emcod_per , CASE WHEN fec.employmentstatus_code IS NOT NULL AND fec.employmentstatus_code = e.employ_code THEN fec.employmentstatus_code ELSE '-' END emcod , CASE WHEN fjs.period_code IS NULL AND per.period_code = fjs.period_code OR fjs.jobstatuscode IS NULL AND per.period_code NOT IN (SELECT bb.period_code FROM tpmrperiodfilterjobstatuscode bb where bb.company_code ='#request.scookie.cocode#' group by period_code) THEN '-' ELSE per.period_code END fjs_per , CASE WHEN fjs.jobstatuscode IS NOT NULL AND fjs.jobstatuscode = e.job_status_code THEN fjs.jobstatuscode ELSE '-' END fjs , per.period_name_#request.scookie.lang# AS formname, per.reference_date AS formdate:date, CONVERT ( per.reference_date, char(10) ) AS refdate, ( SELECT req.req_no FROM tcltrequest req LEFT JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' WHERE eh.period_code = per.period_code AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid and eh.period_code = per.period_code AND eh.reviewee_posid = e.position_id ORDER BY eh.modified_date DESC limit 1 ) AS reqno, CASE  WHEN        (           SELECT    CASE        WHEN       req.req_no IS NOT NULL       THEN              reqsts.name_#request.scookie.lang#   ELSE    'Not Requested'   END    reqstatus   FROM   tcltrequest req               INNER JOIN                 tpmdperformance_evalh eh       ON eh.request_no = req.req_no                  AND req.req_type = 'PERFORMANCE.EVALUATION'   INNER JOIN         tgemreqstatus reqsts                  ON req.status = reqsts.code            WHERE              req.reqemp = e.emp_id               AND req.reqemp = e.emp_id               AND req.company_id = #REQUEST.SCOOKIE.COID#        AND req.reqemp = eh.reviewee_empid  AND eh.period_code = per.period_code               AND EH.head_status = 0       AND EH.lastreviewer_empid = '#request.scookie.user.empid#'     AND eh.reviewee_posid = e.position_id    ORDER BY              eh.modified_date DESC     limit 1    )        IS NOT NULL      THEN        'Draft'      ELSE CASE WHEN ( SELECT CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code AND eh.reviewee_posid = e.position_id ORDER BY eh.modified_date DESC limit 1 ) IS NULL THEN 'Not Requested' ELSE ( SELECT CASE WHEN req.req_no IS NOT NULL THEN reqsts.name_#request.scookie.lang# ELSE 'Not Requested' END reqstatus FROM tcltrequest req INNER JOIN tpmdperformance_evalh eh ON eh.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' INNER JOIN tgemreqstatus reqsts ON req.status = reqsts.code WHERE req.reqemp = e.emp_id AND req.reqemp = e.emp_id AND req.company_id = #request.scookie.coid# AND req.reqemp = eh.reviewee_empid AND eh.period_code = per.period_code AND eh.reviewee_posid = e.position_id ORDER BY eh.modified_date DESC limit 1 ) END END AS reqstatus, ( SELECT eh.isfinal FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.reviewee_posid = e.position_id  AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS isfinal, ( SELECT eh.modified_date FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.reviewee_posid = e.position_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS modified_date, ( SELECT eh.form_no FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.reviewee_posid = e.position_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS formno, ( SELECT eh.score FROM tpmdperformance_evalh eh WHERE eh.reviewee_empid = e.emp_id AND eh.reviewee_posid = e.position_id  AND eh.period_code = per.period_code AND eh.company_code = per.company_code ORDER BY eh.modified_date DESC limit 1 ) AS score1, ( select p2.full_name from TCLTREQUEST REQ inner join tpmdperformance_evalh eh ON EH.request_no = REQ.req_no AND REQ.req_type = 'PERFORMANCE.EVALUATION' inner join TEOMEMPPERSONAL P2 on P2.emp_id = EH.lastreviewer_empid where eh.period_code = per.period_code and REQ.reqemp = E.emp_id AND eh.reviewee_empid = e.emp_id  AND eh.reviewee_posid = e.position_id order by eh.MODIFIED_DATE desc limit 1 ) AS lastreviewer, 'Org Unit Objective' AS linkorg, ( SELECT ef.final_conclusion FROM tpmdperformance_final ef INNER JOIN tpmdperformance_evalh eh ON ef.form_no = eh.form_no AND ef.company_code = eh.company_code WHERE eh.reviewee_empid = e.emp_id AND eh.reviewee_posid = e.position_id AND eh.period_code = per.period_code AND eh.company_code = per.company_code limit 1 ) AS final_conclusion, ( SELECT CASE WHEN eh.isfinal = 1 THEN ef.final_conclusion ELSE '' END AS conclusion FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no INNER JOIN tpmdperformance_final ef ON ef.form_no = eh.form_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.reviewee_posid = e.position_id AND eh.period_code = per.period_code limit 1 ) AS conclusion, ( SELECT CASE WHEN eh.isfinal = 1 AND length(eh.conclusion) <> 0 THEN round(eh.score, 2) ELSE NULL END AS score FROM tcltrequest plr INNER JOIN tpmdperformance_evalh eh ON plr.req_no = eh.request_no AND plr.req_type = 'PERFORMANCE.EVALUATION' AND eh.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE eh.reviewee_empid = e.emp_id AND eh.reviewee_posid = e.position_id AND eh.period_code = per.period_code ORDER BY eh.modified_date DESC limit 1 ) AS score, ( SELECT CASE WHEN plr.status IN ( 3, 9 ) THEN ph.form_no ELSE NULL END AS planformno FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.reviewee_posid = e.position_id  AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planformno, ( SELECT plr.req_no FROM tcltrequest plr INNER JOIN tpmdperformance_planh ph ON ph.request_no = plr.req_no AND plr.req_type = 'PERFORMANCE.PLAN' AND ph.isfinal = 1 AND plr.company_id = #request.scookie.coid# WHERE ph.reviewee_empid = e.emp_id AND ph.reviewee_posid = e.position_id AND ph.period_code = per.period_code ORDER BY ph.modified_date DESC limit 1 ) AS planreqno, per.final_startdate, per.final_enddate, ( SELECT eh2.score AS score2 FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = e.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS score2, ( SELECT eh2.reviewer_empid AS reviewer_empid FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = e.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS reviewer_empid, ( SELECT round(eh2.score, 2) AS loginscore FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id AND eh2.reviewee_posid = e.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginscore, ( SELECT eh2.conclusion AS loginconclusion FROM tpmdperformance_evalh eh2 INNER JOIN tcltrequest req ON eh2.request_no = req.req_no AND req.reqemp = eh2.reviewee_empid AND eh2.reviewer_empid = '#request.scookie.user.empid#' WHERE eh2.period_code = per.period_code AND per.company_code = '#request.scookie.cocode#' AND eh2.company_code = per.company_code AND eh2.reviewee_empid = e.emp_id  AND eh2.reviewee_posid = e.position_id ORDER BY eh2.modified_date DESC limit 1 ) AS loginconclusion, ( SELECT count(b.form_no) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id AND b.reviewee_posid = e.position_id ) AS row_number, ( SELECT max(b.modified_date) FROM tpmdperformance_evalh b INNER JOIN tcltrequest req ON b.request_no = req.req_no AND req.req_type = 'PERFORMANCE.EVALUATION' AND req.company_id = #request.scookie.coid# AND req.reqemp = b.reviewee_empid AND req.status <> 5 INNER JOIN tpmdperformance_evalh eh ON eh.form_no = b.form_no AND eh.modified_date < b.modified_date AND req.req_no = eh.request_no WHERE b.reviewee_empid = e.emp_id AND b.reviewee_posid = e.position_id ) AS max_modified_date">
			           
			            </cfif>
				    
				    </cfif>
			    
					<cfset LOCAL.lsTable="TEODEMPCOMPANY E INNER JOIN TEOMEMPPERSONAL P ON P.emp_id = E.emp_id  INNER JOIN TEOMPOSITION POS ON POS.position_id = E.position_id AND POS.company_id = E.company_id INNER JOIN TEOMPOSITION DEP ON DEP.position_id = POS.parent_id AND DEP.company_id = POS.company_id INNER JOIN TEOMEMPLOYMENTSTATUS ES ON ES.employmentstatus_code = E.employ_code INNER JOIN TPMMPERIOD PER ON PER.company_code = '#request.scookie.cocode#' LEFT JOIN view_jfl JFL ON JFL.period_code = PER.period_code and JFL.EMP_ID = E.EMP_ID and JFL.position_id = E.position_id LEFT JOIN TPMRPERIODFILTEREMPLOYCODE FEC ON PER.PERIOD_CODE = FEC.period_code AND FEC.employmentstatus_code = E.employ_code LEFT JOIN TPMRPERIODFILTERJOBSTATUSCODE FJS ON FJS.PERIOD_CODE = PER.period_code AND FJS.jobstatuscode = E.job_status_code">
					<cfset LOCAL.lsFilter="company_id={COID}  AND (final_startdate <= '#inp_enddt#' AND final_enddate >= '#inp_startdt#') AND (( JFL_PER <> '-' AND JFL = EMP_ID) OR (JFL_PER = '-')) AND ((EMCOD_PER <> '-' AND EMCOD = employ_code) OR (EMCOD_PER ='-')) AND ((FJS_PER <> '-' AND FJS = job_status_code) OR (FJS_PER ='-'))">
					
					<cfif not structkeyexists(StrckTemp,"qLookup")>

					<cfelse>
						<cfset LOCAL.qTemp = StrckTemp.qLookup>
						<cfif qTemp.recordcount>
							<cfset lsFilter=lsFilter & " AND emp_id IN (#quotedvaluelist(qTemp.nval)#)">
						<cfelse>
							<cfset lsFilter=lsFilter & " AND emp_id IN ('')">
						</cfif>  
					</cfif>
				
				<cfset lsFilter=lsFilter & " and (isfinal=1 or isfinal is null or isfinal <> 1)">
				<cfif ReturnVarCheckCompParam eq true>
				    	<cfset lsFilter=lsFilter & " and ((max_modified_date IS null AND row_number = 0) OR (max_modified_date is not null AND row_number > 0)) and ((planformno <> '') OR (FORMNO <> ''))">
				<cfelse>
					<cfset lsFilter=lsFilter & " and ((max_modified_date IS null AND row_number = 0) OR (max_modified_date is not null AND row_number > 0)) ">
				</cfif>
			
				<cfif len(StrckTemp.filterTambahan)>	
					<cfset lsFilter=lsFilter & " #StrckTemp.filterTambahan#">
				</cfif>
				
				<cfif structkeyexists(scParam,"emp_pos")>
					<cfset lsFilter=lsFilter & " AND emp_pos LIKE '%#scParam.emp_pos#%'">
					<cfset StructDelete(scParam,"emp_pos")>
				</cfif>
				<cfif structkeyexists(scParam,"emp_name")>
					<cfset lsFilter=lsFilter & " AND emp_name LIKE '%#scParam.emp_name#%'">
					<cfset StructDelete(scParam,"emp_name")>
				</cfif>
				<cfif structkeyexists(scParam,"conclusion")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN isfinal = 1 AND final_conclusion LIKE '%#scParam.conclusion#%' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"conclusion")>
				</cfif>
				<cfif structkeyexists(scParam,"score")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN isfinal = 1 AND LEN(final_conclusion) <> 0 AND Str(score1, 10, 3) LIKE '%#scParam.score#%' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"score")>
				</cfif>
				<cfif structkeyexists(scParam,"loginconclusion")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN loginconclusion LIKE '%#scParam.loginconclusion#%' AND reviewer_empid = '#request.scookie.user.empid#' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"loginconclusion")>
				</cfif>
				<cfif structkeyexists(scParam,"loginscore")>
					<cfset lsFilter=lsFilter & " AND 1 = CASE WHEN Str(score2, 10, 2) LIKE '%#scParam.loginscore#%' AND reviewer_empid = '#request.scookie.user.empid#' THEN 1 ELSE 0 END">
					<cfset StructDelete(scParam,"loginscore")>
				</cfif>
			
				<cfset ListingData(scParam,{fsort='emp_name,emp_no, formdate ,formname',lsField=lsField,lsTable=lsTable,lsFilter=lsFilter,pid="emp_id"})>
			<!---
			<cfif request.sCOOKIE.user.uname eq "beng.gomez">
				<cf_sfwritelog dump="sqlquery,qdata" prefix="debuglagi" type="sferr">
			</cfif>  ---->
		</cffunction> 
		
		<cffunction name="getPerformanceEvaluation">
		    <cfreturn Listing()>
		</cffunction>
		
		<cffunction name="listingFilter">	
		    <cfargument name="fromInbox" default="false">    
			<cfparam name="search" default="">
			<cfparam name="getval" default="id">
			<cfparam name="autopick" default="">
			<cfparam name="jsfunc" default="null">
            <cfparam name="inp_startdt" default="">
            <cfparam name="inp_enddt" default="">
            <cfset LOCAL.nowdate= DATEFORMAT(CreateDate(Datepart('yyyy',now()),Datepart('m',now()),Datepart('d',now())),'yyyy-mm-dd')>
            <cfif inp_startdt eq "">
                <cfset inp_startdt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_startdt),Datepart("m",inp_startdt),Datepart("d",inp_startdt)),"yyyy-mm-dd")>
            </cfif>
            <cfif inp_enddt eq "">
                <cfset inp_enddt= DATEFORMAT(CreateDate(Datepart("yyyy",inp_enddt),Datepart("m",inp_enddt),Datepart("d",inp_enddt)),"yyyy-mm-dd")>
            </cfif>
            
            
			<cfquery name="local.qPeriod" datasource="#request.sdsn#">
    			select period_code from tpmmperiod where final_enddate >= '#inp_startdt#' AND final_startdate <= '#inp_enddt#' and company_code = '#REQUEST.SCOOKIE.COCODE#'
    		</cfquery>
	
			<cfset LOCAL.searchText=trim(search)>
			<cfset LOCAL.ObjectApproval="PERFORMANCE.Evaluation">
			<cfset LOCAL.lsValidEmp_id = "">
			<cfset LOCAL.ReqAppOrder = "-">
			<cfset LOCAL.retType = "sql">
			<cfset LOCAL.retType = "lsempid">
			<cfset LOCAL.strFilterReqFor = "">
			<cfset LOCAL.arrSqlReqFor= ArrayNew(1) /> 
			<cfset LOCAL.arrsubsql = ArrayNew(1) />
			<cfset LOCAL.arrRevWrd = ArrayNew(1) />
			<cfset LOCAL.isFltEndDt=true />
			<cfset local.strckReturn = structnew()>
            <cfset strckReturn.filterTambahan = "">
			<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			<cfif autopick eq "" OR autopick eq "yes"><!---Lookup onSearch or onBlur.--->
				<cfquery name="LOCAL.qReqUSelf" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
					SELECT field_name,field_value
					FROM TCLCAPPCOMPANY 
					WHERE module='Workflow' 
					AND (field_code = 'exrequself' AND ',' #REQUEST.DBSTRCONCAT# field_value #REQUEST.DBSTRCONCAT# ',' like '%,#LOCAL.ObjectApproval#,%')
					AND company_id = <cfqueryparam value="#REQUEST.scookie.COID#" cfsqltype="CF_SQL_INTEGER"/>
				</cfquery>
				<cfif ReturnVarCheckCompParam eq true>
					<cfset ReqAppOrder = "-">
					<cfquery name="local.qGetFromEvalGen" datasource="#request.sdsn#">
						select distinct reviewee_empid from tpmdperformance_evalgen where reviewer_empid = '#REQUEST.SCookie.User.empid#'
						<cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
							AND period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
						</cfif>
					</cfquery>
					<cfif qGetFromEvalGen.recordcount gt 0 >
						<cfset lsValidEmp_id = ValueList(qGetFromEvalGen.reviewee_empid)>
					</cfif>
				<cfelse> 
					<!-- if not pregenerate ---->
					<cfset LOCAL.Requester = Application.SFDB.RunQuery("SELECT * FROM VIEW_EMPLOYEE WHERE emp_id = ? AND company_id = ?", [[REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"],[REQUEST.scookie.COID, "CF_SQL_INTEGER"]]).QueryRecords/>
					<cfif APPLICATION.CFMLENGINE neq "Railo">
						<cfif not cacheRegionExists("inpRequestFor")>
							<cfset cacheRegionNew("inpRequestFor")>
						</cfif>
						<cfset LOCAL.scQAttr={cacheregion="inpRequestFor"}>
					<cfelse>
						<cfset LOCAL.scQAttr={}>
					</cfif>
					<cfset LOCAL.strUdrScr=(request.dbdriver eq "MYSQL"?"\_":"_")>
					<cfset LOCAL.filterFrmlSet="request_approval_formula like '%"&replacenocase("EMP_"&requester.emp_no,"_",strUdrScr,"ALL")& "%' ">
					<cfset filterFrmlSet &= " OR request_approval_formula like '%"&replacenocase("EMP_CUSTOMFIELD","_",strUdrScr,"ALL")& "%' ">
					<cfset filterFrmlSet &= " OR request_approval_formula like '%"&replacenocase("POS_CUSTOMFIELD","_",strUdrScr,"ALL")& "%' ">
					<cfif len(requester.pos_code)>
						<cfset filterFrmlSet &= "OR request_approval_formula like '%"&replacenocase("POS_"&requester.pos_code,"_",strUdrScr,"ALL")& "%' ">
					</cfif>
					<cftry> 
						<cfquery name="qnewassig" datasource="#request.sdsn#">
							SELECT emp_id, position_code FROM TCALNEWASSIGNMENT WHERE emp_id = '#requester.emp_id#'
						</cfquery>
						<cfif qnewassig.recordcount gt 0>
							<cfset filterFrmlSet &= "OR request_approval_formula like '%"&replacenocase("POS_"&qnewassig.position_code,"_",strUdrScr,"ALL")& "%' ">
						</cfif>
						<cfcatch></cfcatch>
					</cftry>
					<cfloop list="spv,mgr" index="LOCAL.idxspvmgr">
						<cfloop list="'',/,+" index="LOCAL.idxprefrm">
							<cfset filterFrmlSet &= " OR request_approval_formula like '%"&idxprefrm&idxspvmgr&"%'">
						</cfloop>
					</cfloop>
					<cfquery name="LOCAL.qReserveWordSet" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
						SELECT reserve_word_code FROM TSFMREQAPPRSRVWORD
					</cfquery>
					<cfloop query="qReserveWordSet">
						<cfset filterFrmlSet &= " OR request_approval_formula like '%"&replacenocase(qReserveWordSet.reserve_word_code,"_",strUdrScr,"ALL")&"%'">
					</cfloop>
						<cfloop condition="ListLen(LOCAL.ObjectApproval, '.') GT 0"><!---loop if LOCAL.ObjectApproval is len--->
							<cfquery name="LOCAL.qRequestApprovalOrder" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
								SELECT seq_id,
										req_order,
										request_approval_name,
										request_approval_formula,
										requester fltrequester,
										requestee fltrequestee
								FROM	TCLCReqAppSetting
								WHERE	company_id = <cfqueryparam value="#REQUEST.scookie.COID#" cfsqltype="CF_SQL_INTEGER"/>
									AND request_approval_code = <cfqueryparam value="#LOCAL.ObjectApproval#" cfsqltype="CF_SQL_VARCHAR">
									<cfif request.dbdriver eq "ORACLE">
										AND (requester IS not NULL OR requestee is not null)
									<cfelse>
										AND (requester <> '' OR requestee <> '')
									</cfif>
									AND (<cfif len(filterFrmlSet)>#PreserveSingleQuotes(filterFrmlSet)#</cfif>)
								ORDER BY req_order DESC
							</cfquery>
							
							<cfloop query="qRequestApprovalOrder">
								<cftry>
								<cfset LOCAL.lstRequestee = "" />
								<cfset LOCAL.sqlRequestee = "" />
								<cfset LOCAL.sqlRequester = "" />
								<cfset LOCAL.fltrRequesteeTemp = "" />
								<cfif qRequestApprovalOrder.fltrequestee neq "" AND qRequestApprovalOrder.fltrequestee neq "[GENERAL]">
									<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
									<!---<cfset qRequestApprovalOrder.fltrequestee = REReplace(qRequestApprovalOrder.fltrequestee, "'male'",1, "ALL") />
									<cfset qRequestApprovalOrder.fltrequestee = REReplace(qRequestApprovalOrder.fltrequestee, "'female'",0, "ALL") />
									
									<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
										SELECT	emp_id
										FROM	VIEW_EMPLOYEE
										WHERE	#PreserveSingleQuotes(qRequestApprovalOrder.fltrequestee)#
									</cfquery>
									<cfset lstRequestee = ValueList(qCekRequestee.emp_id) />--->
									<cfset LOCAL.sqlRequestee = REReplace(REReplace(qRequestApprovalOrder.fltrequestee, "'male'",1, "ALL"), "'female'",0, "ALL") />
									<cftry>
										<cfset fltrRequesteeTemp = "SELECT VE.emp_id FROM VIEW_EMPLOYEE VE WHERE " & LOCAL.sqlRequestee />
										<cfset LOCAL.sqlRequestee = Evaluate(DE(LOCAL.sqlRequestee)) />
										<cfif retType eq "sql">
											<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#" attributeCollection=#scQAttr#>
												SELECT emp_id FROM VIEW_EMPLOYEE WHERE 1=0 AND (#PreserveSingleQuotes(LOCAL.sqlRequestee)#)
											</cfquery>
										<cfelse>
											<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#" attributeCollection=#scQAttr#>
												SELECT emp_id FROM VIEW_EMPLOYEE WHERE (#PreserveSingleQuotes(LOCAL.sqlRequestee)#)
											</cfquery>
											<cfset lstRequestee = ValueList(qCekRequestee.emp_id) />
										</cfif>
									<cfcatch>
										<cfset LOCAL.sqlRequestee = ""/>
										<cfset fltrRequesteeTemp = ""/>
										<cfif isdefined("URL.devdmp")>
											<cfdump var="#cfcatch#" label="cfcatch">
										</cfif>
										<cfcontinue>
									</cfcatch>
									</cftry>
								</cfif>
								<cfset LOCAL.procValidEmp_id=false />
								<cfif qRequestApprovalOrder.fltrequester neq "" AND qRequestApprovalOrder.fltrequester neq "[GENERAL]">
									<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
									<!---<cfset qRequestApprovalOrder.fltrequester = REReplace(qRequestApprovalOrder.fltrequester, "'male'",1, "ALL") />
									<cfset qRequestApprovalOrder.fltrequester = REReplace(qRequestApprovalOrder.fltrequester, "'female'",0, "ALL") />
									<cfquery name="LOCAL.qCekRequester" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
										SELECT	emp_id 
										FROM	VIEW_EMPLOYEE
										WHERE	emp_id = <cfqueryparam value="#REQUEST.SCookie.User.EMPID#" cfsqltype="CF_SQL_VARCHAR"> AND
												#PreserveSingleQuotes(qRequestApprovalOrder.fltrequester)#
									</cfquery>

									<cfif qCekRequester.RecordCount>
										<cfset procValidEmp_id=true />
									</cfif>--->
									<cfset LOCAL.sqlRequester = REReplace(REReplace(qRequestApprovalOrder.fltrequester, "'male'",1, "ALL"), "'female'",0, "ALL") />
									<cftry>
										<!---<cfset LOCAL.sqlRequester = qRequestApprovalOrder.fltrequester />--->
										<cfset LOCAL.sqlRequester = Evaluate(DE(LOCAL.sqlRequester)) />
										<cfquery name="LOCAL.qCekRequester" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#" attributeCollection=#scQAttr#>
											SELECT emp_id FROM VIEW_EMPLOYEE 
											WHERE emp_id = <cfqueryparam value="#REQUEST.SCookie.User.EMPID#" cfsqltype="CF_SQL_VARCHAR">
												AND (#PreserveSingleQuotes(LOCAL.sqlRequester)#)
										</cfquery>
										<cfif qCekRequester.RecordCount>
											<cfset procValidEmp_id=true />
										<cfelse>
											<cfcontinue>
										</cfif>
										<cfcatch>
											<cfif isdefined("URL.devdmp")>
												<cfdump var="#cfcatch#" label="cfcatch">
											</cfif>
											<cfcontinue>
										</cfcatch>
									</cftry>
								<cfelse>
									<cfset procValidEmp_id=true />
								</cfif>
								<cfif procValidEmp_id>
									<cfset LOCAL.arrEmployee = objRequestApproval.GetEmployeeFromFormula(qRequestApprovalOrder.request_approval_formula, REQUEST.SCookie.User.EMPID, 1, isFltEndDt, -1, retType,requester, requester) />
									
									<cfif arrayLen(arrEmployee)>
										<cfset LOCAL.idxEmployee = "">
										<cfloop array="#arrEmployee#" index="idxEmployee">
											
											<cfif ListFind(lstRequestee, idxEmployee['emp_id'])>
												<cfif (qRequestApprovalOrder.fltrequestee eq "" or qRequestApprovalOrder.fltrequestee eq "[GENERAL]")>
													<cfif ListFind(lsValidEmp_id, idxEmployee['emp_id']) lt 1>
														<cfset lsValidEmp_id = ListAppend(lsValidEmp_id, idxEmployee['emp_id']) />
													</cfif>
												<cfelseif qRequestApprovalOrder.fltrequestee neq "">
													<cfif ListFind(lsValidEmp_id, idxEmployee['emp_id']) lt 1>
														<cfset lsValidEmp_id = ListAppend(lsValidEmp_id, idxEmployee['emp_id']) />
													</cfif>
												</cfif>
												
											</cfif>
										</cfloop>
									</cfif>
								</cfif>
								
								<cfif Len(lsValidEmp_id)>
									<cfset ReqAppOrder = qRequestApprovalOrder.req_order>
									
								</cfif>
								
								<cfcatch></cfcatch>
								</cftry>
							</cfloop>
							<cfbreak>
						</cfloop>
					<!-- end if not pregenerate ---->
				</cfif>
				
				
				
			</cfif>
			
		<!---	<cfif request.sCOOKIE.user.uname eq "joie.lopez" >
				<cf_sfwritelog dump="lsValidEmp_id,ReqAppOrder" prefix="testlsValidEmp_id" type="sferr">
			</cfif> --->
			<cfif arguments.fromInbox>
				<cfreturn ReqAppOrder>
			<cfelse>
			<cfif retType eq "sql">
				<cfloop array="#LOCAL.arrSqlReqFor#" index="LOCAL.idxSqlReqFor">
					<cfset LOCAL.strrevwrd="">
					<cfset LOCAL.isallempcom = false>
					<cfset LOCAL.strSqlRequesteeTmp="">
					<cfif len(trim(idxSqlReqFor.sqlRequestee))>
						<cfset LOCAL.strSqlRequesteeTmp=" AND (#idxSqlReqFor.sqlRequestee#) ">
					</cfif>
					<cfloop array="#idxSqlReqFor.arrRevWrd#" index="LOCAL.idxsqlclrequestee">
						<cfif len(idxsqlclrequestee.revwrdsql)>
							<cfset LOCAL.strrevwrd = ListAppend(strrevwrd, " OR ((#idxsqlclrequestee.revwrdsql#) #strSqlRequesteeTmp#)"," ") />
						</cfif>
						<cfif listFIndNoCase("POS_,EMP_",idxsqlclrequestee.revwrdtype) and idxSqlReqFor.sqlRequestee eq "">
							<cfset LOCAL.strFilterReqFor = " #idxsqlclrequestee.revwrdsql# " />
							<cfset isallempcom = true>
							<cfbreak>
						</cfif>
					</cfloop>
					<cfif isallempcom>
						<cfbreak>
					</cfif>
					<cfif len(strrevwrd)>
						<cfset LOCAL.strFilterReqFor = ListAppend(LOCAL.strFilterReqFor, " OR (1=0 #strrevwrd#)"," ") />
						<!---<cfif len(idxSqlReqFor.sqlRequestee)>
							<cfset LOCAL.strFilterReqFor = ListAppend(LOCAL.strFilterReqFor, " OR ((1=0 #strrevwrd#) AND #idxSqlReqFor.sqlRequestee#)"," ") />
						<cfelse>
							<cfset LOCAL.strFilterReqFor = ListAppend(LOCAL.strFilterReqFor, " OR (1=0 #strrevwrd#)"," ") />
						</cfif>--->
					</cfif>
				</cfloop>
				<cfif len(LOCAL.strFilterReqFor)>
					<cfset LOCAL.isfieldtemp1 = UCase(requester.columnlist)>
					<cfset LOCAL.isfieldtemp2 = "E." & ReplaceNoCase(LOCAL.isfieldtemp1,",",",E.")>
					<cfset LOCAL.strFilterReqFor = ReplaceList(UCase(LOCAL.strFilterReqFor), LOCAL.isfieldtemp1, LOCAL.isfieldtemp2)>
				</cfif>
				<cfif isdefined("URL.devdmp")>
					<cfdump var="#LOCAL.arrSqlReqFor#" label="LOCAL.arrSqlReqFor">
					<cfdump var="#LOCAL.strFilterReqFor#" label="LOCAL.strFilterReqFor">
				</cfif>
			</cfif>
			
    		<cfif ListFind(lsValidEmp_id, REQUEST.SCookie.User.empid) lt 1>
    			<cfset lsValidEmp_id = ListAppend(lsValidEmp_id, REQUEST.SCookie.User.empid)/>
    		</cfif>
			
			<!----<cf_sfwritelog dump="lsValidEmp_id" prefix="lsValidEmp_idkedua"> ---->

            <!---
			<cfquery name="local.qPeriod" datasource="#request.sdsn#">
    			select period_code from tpmmperiod where final_enddate >= '#inp_startdt#' AND final_startdate <= '#inp_enddt#'
    		</cfquery>--->
			    
           
		    	<cfif ReturnVarCheckCompParam eq true>
					 <cfquery name="local.qTempYan" datasource="#request.sdsn#">
						 SELECT reviewee_empid emp_id, 
						  period_code 
						FROM 
						  TPMDPERFORMANCE_EVALGEN EH 
						WHERE 
						  company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> 
						  AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
                            <cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                            </cfif>
						GROUP BY reviewee_empid, period_code
						UNION 
						SELECT 
						   EC.emp_id, 
						  EH.period_code 
						FROM 
						  TCLTREQUEST REQ LEFT JOIN TEODEMPCOMPANY EC ON ( EC.emp_id = REQ.reqemp  AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar"> )
						 
						  LEFT JOIN TPMDPERFORMANCE_EVALH EH ON EH.reviewee_empid = REQ.reqemp 
						  AND EH.request_no = REQ.req_no 
						 
						WHERE 
						  UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION' 
						  AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						  AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
						GROUP BY emp_id, period_code
					</cfquery>
					
				<cfelse>
					<cfquery name="local.qTempYan" datasource="#request.sdsn#">
					SELECT DISTINCT EC.emp_id,
						EH.period_code
					FROM TCLTREQUEST REQ
					LEFT JOIN TPMDPERFORMANCE_EVALH EH
						ON  EH.reviewee_empid = REQ.reqemp 
						AND EH.request_no = REQ.req_no
					LEFT JOIN TEODEMPCOMPANY EC ON EC.emp_id = REQ.reqemp
						AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					WHERE UPPER(REQ.req_type) = 'PERFORMANCE.EVALUATION'
						AND REQ.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						AND (
							REQ.approval_list LIKE <cfqueryparam value="#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#,%" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list LIKE <cfqueryparam value="%,#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
							OR
							REQ.approval_list = <cfqueryparam value="#request.scookie.user.uid#" cfsqltype="cf_sql_varchar">
						)
                        <cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
                            AND EH.period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
                        </cfif>
					</cfquery>
			</cfif>
			
		  
    		<cfset local.caseDiffAppr = "">
            <cfset local.lstEmpDiffAppr = "">
			
           <cfloop query="qTempYan">
            	<cfif ListFind(lsValidEmp_id, qTempYan.emp_id) lt 1>
    				<cfset lsValidEmp_id = ListAppend(lsValidEmp_id, qTempYan.emp_id)/>
                    <cfset lstEmpDiffAppr = ListAppend(lstEmpDiffAppr,qTempYan.emp_id)>
                    <cfquery name="LOCAL.getPeriodCodeEmpReq" dbtype="query"> <!---Tambahan replace approver--->
                        SELECT period_code FROM qTempYan 
                        WHERE EMP_ID = <cfqueryparam value="#qTempYan.emp_id#" cfsqltype="CF_SQL_VARCHAR"/>
					</cfquery>
					<cfif ReturnVarCheckCompParam eq true>
						<cfif qTempYan.emp_id neq "">
							<cfset caseDiffAppr = caseDiffAppr & "WHEN emp_id IN ('#qTempYan.emp_id#') AND periodcode IN (#getPeriodCodeEmpReq.recordcount neq 0 ? quotedvaluelist(getPeriodCodeEmpReq.period_code) : "'-'"#) THEN 1 ">
						</cfif>
						
					<cfelse>
					   <cfif qTempYan.emp_id neq "">
							<cfset caseDiffAppr = caseDiffAppr & "WHEN emp_id IN ('#qTempYan.emp_id#') OR periodcode IN (#getPeriodCodeEmpReq.recordcount neq 0 ? quotedvaluelist(getPeriodCodeEmpReq.period_code) : "'-'"#) THEN 1 ">
					   </cfif>
					</cfif>
    			</cfif>
            </cfloop>
			
            <cfif listlen(lstEmpDiffAppr)>
    	        <cfset lstEmpDiffAppr = ListQualify(lstEmpDiffAppr,"'",",")>
    	        <cfset caseDiffAppr = "AND 1 = CASE " & caseDiffAppr & " WHEN emp_id NOT IN (#lstEmpDiffAppr#) THEN 1 ELSE 0 END ">
            </cfif>
			
			<cfquery name="local.qUploadedData" datasource="#request.sdsn#">
				SELECT reviewee_empid emp_id, period_code FROM TPMDPERFORMANCE_FINAL WHERE is_upload = 'Y' and company_code = '#REQUEST.SCOOKIE.COCODE#'
				<cfif qPeriod.recordcount gt 0 and qPeriod.period_code neq "">
					AND period_code IN (<cfqueryparam value="#ValueList(qPeriod.period_code)#" list="yes" cfsqltype="cf_sql_varchar">)
				</cfif>
			</cfquery>
			<cfloop query="qUploadedData">
				<cfif ListFind(lsValidEmp_id, qUploadedData.emp_id) gt 0>
					<cfquery name="LOCAL.getUploadedEmployee" dbtype="query"> 
						SELECT period_code FROM qUploadedData 
						WHERE EMP_ID = <cfqueryparam value="#qUploadedData.emp_id#" cfsqltype="CF_SQL_VARCHAR"/>
					</cfquery>
					<cfset caseDiffAppr = caseDiffAppr & "AND 1 = CASE WHEN emp_id IN ('#qUploadedData.emp_id#') AND periodcode IN (#getUploadedEmployee.recordcount neq 0 ? quotedvaluelist(getUploadedEmployee.period_code) : "'-'"#) THEN 0 ELSE 1 END ">
				</cfif>
			</cfloop>
			
            <cfset strckReturn.filterTambahan = caseDiffAppr>
         
    		<cfset LOCAL.arrValue = ArrayNew(1)/>
		
			<cfif retType eq "sql">
				<cfsavecontent variable="LOCAL.sqlQuery">
					<cfoutput>
					SELECT E.emp_id, E.emp_id nval
						,E.full_name#REQUEST.DBSTRCONCAT#' ('#REQUEST.DBSTRCONCAT#E.emp_no#REQUEST.DBSTRCONCAT#')' ntitle 
						<cfif REQUEST.SCOOKIE.MODE eq "SFGO">,E.full_name,E.emp_no,E.pos_name_en,E.photo</cfif>
					FROM VIEW_EMPLOYEE E
					WHERE 
						<cfif REQUEST.Scookie.User.UTYPE neq 9>
							E.company_id = ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.COID, "cf_sql_integer"])/> 
							AND (E.end_date >= ? <cfset ArrayAppend(arrValue, [CreateODBCDate(Now()), "CF_SQL_TIMESTAMP"])/> OR E.end_date IS NULL) 
							<cfif len(searchText) AND searchText neq "???">
								AND (
									E.full_name LIKE ? <cfset ArrayAppend(arrValue, ["%#searchText#%", "CF_SQL_VARCHAR"])/> 
									OR E.emp_no = ? <cfset ArrayAppend(arrValue, ["#searchText#", "CF_SQL_VARCHAR"])/>
								) 
							</cfif>
							<cfif retType eq "sql">
								AND (E.emp_id = ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"])/> 
									<cfif len(LOCAL.strFilterReqFor)>
										OR (1=0 #preservesinglequotes(LOCAL.strFilterReqFor)#)
									</cfif>
									<cfset LOCAL.arrValidEmp_id = listToArray(lsValidEmp_id,",") />
									<cfset LOCAL.lsLimit = 1000 />
									<cfloop index="LOCAL.idx" from="1" to="#arrayLen(arrValidEmp_id)#" step="#lsLimit#">
										OR E.emp_id IN (<cfloop index="LOCAL.sub" from="#idx#" to="#idx+(lsLimit-1)#" step="1"><cfif not arrayisdefined(arrValidEmp_id,sub)><cfbreak></cfif><cfif sub gt idx>,</cfif>'#arrValidEmp_id[sub]#'</cfloop>)
									</cfloop>
								)
							<cfelse>
								<cfif len(lsValidEmp_id)>
									AND ( <!---split the list into smaller list--->
										<cfset LOCAL.arrValidEmp_id = listToArray(lsValidEmp_id,",") />
										<cfset LOCAL.lsLimit = 1000 />
										<cfloop index="LOCAL.idx" from="1" to="#arrayLen(arrValidEmp_id)#" step="#lsLimit#">
											<cfif idx gt 1>OR</cfif> E.emp_id IN (<cfloop index="LOCAL.sub" from="#idx#" to="#idx+(lsLimit-1)#" step="1"><cfif not arrayisdefined(arrValidEmp_id,sub)><cfbreak></cfif><cfif sub gt idx>,</cfif>'#arrValidEmp_id[sub]#'</cfloop>)
										</cfloop>
									)
								</cfif>
							</cfif>
						<cfelse>
							1=0
						</cfif>
						<cfif qReqUSelf.recordcount>
							AND (E.emp_id != ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"])/>)
						</cfif>
					ORDER BY ntitle
					</cfoutput>
				</cfsavecontent>
			<cfelse>
				<cfsavecontent variable="LOCAL.sqlQuery">
					<cfoutput>
					SELECT DISTINCT E.emp_id nval, #Application.SFUtil.DBConcat(["E.full_name","' ['","EC.emp_no","']'"])# ntitle 
					FROM TEOMEmpPersonal E
						INNER JOIN TEODEmpCompany EC ON E.emp_id= EC.emp_id 
					WHERE 
						<cfif REQUEST.Scookie.User.UTYPE neq 9>
							EC.company_id = ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.COID, "cf_sql_integer"])/> 
							<!---active employee--->
							AND (EC.end_date >= ? <cfset ArrayAppend(arrValue, [CreateODBCDate(Now()), "CF_SQL_TIMESTAMP"])/> OR EC.end_date IS NULL) 
							<cfif len(searchText) AND searchText neq "???">
								AND (
									E.full_name LIKE ? <cfset ArrayAppend(arrValue, ["%#searchText#%", "CF_SQL_VARCHAR"])/> 
									OR EC.emp_no = ? <cfset ArrayAppend(arrValue, ["#searchText#", "CF_SQL_VARCHAR"])/>
								) 
							</cfif>
							<cfif len(lsValidEmp_id)>
								AND ( <!---split the list into smaller list--->
									<cfset LOCAL.arrValidEmp_id = listToArray(lsValidEmp_id,",") />
									<cfset LOCAL.lsLimit = 1000 />
									<cfloop index="LOCAL.idx" from="1" to="#arrayLen(arrValidEmp_id)#" step="#lsLimit#">
										<cfif idx gt 1>OR</cfif> E.emp_id IN (<cfloop index="LOCAL.sub" from="#idx#" to="#idx+(lsLimit-1)#" step="1"><cfif not arrayisdefined(arrValidEmp_id,sub)><cfbreak></cfif><cfif sub gt idx>,</cfif>'#arrValidEmp_id[sub]#'</cfloop>)
									</cfloop>
								)
							</cfif>
							<cfif qReqUSelf.recordcount>
								AND (E.emp_id != ? <cfset ArrayAppend(arrValue, [REQUEST.SCookie.User.EMPID, "CF_SQL_VARCHAR"])/>)
							</cfif>
						<cfelse>
							1=0
						</cfif>
					ORDER BY ntitle
					</cfoutput>
				</cfsavecontent>
			</cfif>
			<cfset LOCAL.qLookup = queryNew("nval,ntitle","Varchar,Varchar")>
	    		<cfset LOCAL.resultQuery = Application.SFDB.RunQuery(sqlQuery, arrValue)/>
	    		<cfif resultQuery.QueryResult>
	    			<cfset qLookup = resultQuery.QueryRecords/>
	    			<cfset LOCAL.vSQL = resultQuery.QueryStruck/>
	                <cfset strckReturn.qLookup = qLookup>
	                <cfset strckReturn.ReqAppOrder = ReqAppOrder>
	    			<cfreturn strckReturn>
	            <cfelse>
	    			<cfreturn 0>
	    		</cfif>
			
			</cfif>
			
		</cffunction>
		
		<cffunction name="getApprovalOrder">
		    <cfargument name="reviewee" default="">
		    <cfargument name="reviewer" default="">
		    <cfif REQUEST.SCOOKIE.MODE eq "SFGO">
		        <cfset arguments.reviewee = FORM.reviewee/>
		        <cfset arguments.reviewer = FORM.reviewer/>
		    </cfif>
		    
			<cfset LOCAL.ObjectApproval="PERFORMANCE.Evaluation">
		    <cfset Local.reqorder = "-">
		    
			<cfquery name="LOCAL.qRequestApprovalOrder" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
				SELECT seq_id,req_order,	request_approval_name,
						request_approval_formula,
						requester,
						requestee
				FROM	TCLCReqAppSetting
				WHERE	company_id = <cfqueryparam value="#REQUEST.scookie.COID#" cfsqltype="CF_SQL_INTEGER"/>
					AND request_approval_code = <cfqueryparam value="#LOCAL.ObjectApproval#" cfsqltype="CF_SQL_VARCHAR">
					AND (requester <> '' OR requestee <> '')
				ORDER BY request_approval_code DESC, req_order DESC, requester DESC, requestee DESC
			</cfquery>
			
			<cfloop query="qRequestApprovalOrder">
			    <cfset local.isValidReviewee = false>
			    <cfset local.isValidReviewer = false>

				<!--- ambil list requestee --->
				<cfset local.lstRequestee = "" />
				<cfif qRequestApprovalOrder.requestee neq "" AND qRequestApprovalOrder.requestee neq "[GENERAL]">
					<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
					<cfset qRequestApprovalOrder.requestee = REReplace(qRequestApprovalOrder.requestee, "'male'",1, "ALL") />
					<cfset qRequestApprovalOrder.requestee = REReplace(qRequestApprovalOrder.requestee, "'female'",0, "ALL") />
					
					<cfquery name="LOCAL.qCekRequestee" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
						SELECT	distinct emp_id FROM	VIEW_EMPLOYEE
						WHERE	#PreserveSingleQuotes(qRequestApprovalOrder.requestee)#
					</cfquery>
					<cfset lstRequestee = ValueList(qCekRequestee.emp_id) />
				<cfelse>
					<cfset local.arrEmployee = objRequestApproval.GetEmployeeFromFormula(strRequestApprovalFormula=qRequestApprovalOrder.request_approval_formula, strEmpId=arguments.reviewer, iEmpType=1,retType="Isempid") />
					<cfloop array="#arrEmployee#" index="local.idxEmployee">
						<cfif not ListFindNoCase(lstRequestee, idxEmployee['emp_id'])>
							<cfset lstRequestee = ListAppend(lstRequestee, idxEmployee['emp_id']) />
						</cfif>
					</cfloop>
				</cfif>
				
    			<!--- TCK0918-196855 Cek apakah requester ada--->
                <cfset LOCAL.procValidEmp_id=false />
    			<cfif qRequestApprovalOrder.requester neq "" AND qRequestApprovalOrder.requester neq "[GENERAL]">
    				<!---this Custom Code based on generate function[need coheren process with request approval setting origin]--->
    				<cfset qRequestApprovalOrder.requester = REReplace(qRequestApprovalOrder.requester, "'male'",1, "ALL") />
    				<cfset qRequestApprovalOrder.requester = REReplace(qRequestApprovalOrder.requester, "'female'",0, "ALL") />
    				
    				<cfquery name="LOCAL.qCekRequester" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
    					SELECT	emp_id FROM	VIEW_EMPLOYEE
    					WHERE	emp_id = <cfqueryparam value="#REQUEST.SCookie.User.EMPID#" cfsqltype="CF_SQL_VARCHAR"> AND
    							#PreserveSingleQuotes(qRequestApprovalOrder.requester)#
    				</cfquery>
    				<cfif qCekRequester.RecordCount>
    					<cfset procValidEmp_id=true />
    				</cfif>
    			<cfelse>
    				<cfset procValidEmp_id=true />
    			</cfif>
                <cfset LOCAL.IsValidRequester=false />
    			<cfif procValidEmp_id>
    			    <cfset LOCAL.arrEmployee = objRequestApproval.GetEmployeeFromFormula(strRequestApprovalFormula=qRequestApprovalOrder.request_approval_formula, strEmpId=REQUEST.SCookie.User.EMPID, iEmpType=1,retType="lsempid") />
    			    <cfif ArrayLen(arrEmployee)>
                        <cfset IsValidRequester=true />
    			    </cfif>
    			</cfif>
    			<!--- TCK0918-196855 Cek apakah requester ada--->
				
				<cfif listfindnocase(lstRequestee,arguments.reviewee) AND (IsValidRequester OR arguments.reviewee EQ arguments.reviewer)> <!--- TCK0918-196855 Cek apakah requester ada | IsValidRequester (TCK1018-197363 - Jika requester sebagai requestee maka ambil workflow terakhir)  --->
				    <cfset reqorder = qRequestApprovalOrder.req_order>
				    <cfbreak>
				</cfif>
			</cfloop>
			
			<cfif REQUEST.SCOOKIE.MODE eq "SFGO">
    			<cfset LOCAL.jsonReturn = structNew()>  
                <cfset jsonReturn['message']="getApprovalOrder sf6">
        		<cfset jsonReturn['data']= reqorder>
    		    <cfreturn deserializeJSON(SerializeJSON(jsonReturn,"struct"))/>
    		<cfelse>
		        <cfreturn reqorder>
		    </cfif>
		</cffunction>
	    
	    <cffunction name="View">
	        <cfparam name="empid" default="">
	        <cfparam name="reqno" default="">
	        <cfparam name="periodcode" default="">
			<cfparam name="varcoid" default="#request.scookie.coid#">
	        <cfset local.nowdate= DATEFORMAT(CreateDate(Datepart("yyyy",now()),Datepart("m",now()),Datepart("d",now())),"mm/dd/yyyy")>
	        
	        <cfquery name="local.qGetReqStatus" datasource="#REQUEST.SDSN#">
	          	SELECT status, requester	FROM	TCLTRequest
	            WHERE	req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					and UPPER(req_type)='PERFORMANCE.EVALUATION'
	        </cfquery>
	        <!--- Untuk cari cari tau apakah form masih dalam finaldate atau tidak --->
	        <cfquery name="local.qFinalDate" datasource="#REQUEST.SDSN#">
	            SELECT  final_startdate, final_enddate  FROM TPMMPERIOD WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfset local.evalsd = DATEFORMAT(#qFinalDate.final_startdate#,"yyyy-mm-dd")>
			<cfset local.evaled = DATEFORMAT(#qFinalDate.final_enddate#,"yyyy-mm-dd")>
	        <cfif evaled lt nowdate>
	            <cfset local.evaldatevalid= 0 >
	        <cfelse>
	            <cfset local.evaldatevalid=1>
	        </cfif>
	        <cfquery name="local.qGetFormDetail" datasource="#request.sdsn#">
	        	SELECT distinct EP.full_name AS empname, EC.emp_no AS empno, EC.position_id AS emppos, EP.photo AS empphoto,
	            	EC.emp_id AS empid, '0' status, '#request.scookie.user.uid#' requester, '#evaldatevalid#' AS evaldatevalid
				FROM TEODEMPCOMPANY EC	INNER JOIN TEOMEMPPERSONAL EP ON EP.emp_id = EC.emp_id
				WHERE EC.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
		            AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	        </cfquery>
			<cfset REQUEST.KeyFields="reviewee_empid=#empid#">
	    	<cfreturn qGetFormDetail>
	    </cffunction>
	    
	    <cffunction name="getEmpWorkLocation">
    	    <cfargument name="empid" default="">
    	    <cfargument name="varcoid" default="#request.scookie.coid#" required="No">
    	    <cfargument name="periodcode" default="">
    	    <!---
    	    <cfquery name="LOCAL.qGetWorkLocation" datasource="#request.sdsn#">
    	        select EH.emp_id,EH.worklocation_code,EH.effectivedt,WL.worklocation_name,EH.enddt
                from TEODEMPLOYMENTHISTORY EH
                LEFT JOIN  TEOMWORKLOCATION WL ON WL.worklocation_code = EH.worklocation_code 
                WHERE  emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                and effectivedt <= (select plan_startdate from TPMMPERIOD where period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
                and EH.company_id =  <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
                order by EH.effectivedt desc 
    	    </cfquery> 
    	    --->
    	    <cfquery name="LOCAL.qGetWorkLocation" datasource="#request.sdsn#">
    	        select EH.emp_id,EH.work_location_code worklocation_code,EH.start_date effectivedt,WL.worklocation_name,EH.end_date enddt
                from TEODEMPCOMPANY EH
                LEFT JOIN  TEOMWORKLOCATION WL ON WL.worklocation_code = EH.work_location_code 
                WHERE  emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                <!--- and EH.start_date <= (select plan_startdate from TPMMPERIOD where period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">) --->
                and EH.company_id =  <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
                AND EH.status = 1
                order by EH.start_date desc 
    	    </cfquery> 
    	    
    	    
    	<Cfreturn qGetWorkLocation>
    </cffunction>	
	    
	    <!--- Evaluation Form --->
	  <cffunction name="getEmpDetail">
	    	<cfargument name="empid" default="">
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">
	        <cf_sfqueryemp name="LOCAL.qGetEmpDetail" datasource="#REQUEST.SDSN#" maxrows="1" ACCESSCODE="hrm.employee" DAFIELD="empid">
	        	<cfoutput>
	        	SELECT distinct EP.full_name AS empname, EC.emp_no AS empno, POS.pos_name_#request.scookie.lang# AS emppos
	            	, ORG.pos_name_#request.scookie.lang# AS orgunit, EP.photo AS empphoto, EP.gender AS empgender
	                , GRD.grade_name AS empgrade, EC.start_date AS empjoindate
	                , EC.emp_id AS empid,EC.employ_code
	            	, POS.position_id AS posid
	            	, POS.dept_id,ES.employmentstatus_name_#request.scookie.lang# emp_status, WL.worklocation_name
				FROM TEODEMPCOMPANY EC
					INNER JOIN TEOMEMPPERSONAL EP ON EP.emp_id = EC.emp_id
	                LEFT JOIN TEOMPOSITION POS ON POS.position_id = EC.position_id <!---AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">--->
	                LEFT JOIN TEOMPOSITION ORG ON ORG.position_id = POS.dept_id <!---AND ORG.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">--->
	                LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = EC.grade_code <!---AND GRD.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">--->
	                LEFT JOIN TEOMEMPLOYMENTSTATUS ES ON EC.employ_code = ES.employmentstatus_code
					 LEFT JOIN TEOMWORKLOCATION WL ON EC.work_location_code = WL.worklocation_code
					WHERE EC.emp_id = <cf_sfqparamemp value="#empid#" cfsqltype="cf_sql_varchar">
		            AND EC.company_id = <cf_sfqparamemp value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		       </cfoutput>
	        </cf_sfqueryemp>
	            <!--- TCK2107-0660305 --->
				<cfif qGetEmpDetail.recordcount eq 0>
					<cfquery name="qGetEmpDetail" datasource="#request.sdsn#">
					 SELECT distinct EP.full_name AS empname, EC.emp_no AS empno, POS.pos_name_#request.scookie.lang# AS emppos
					  , ORG.pos_name_#request.scookie.lang# AS orgunit, EP.photo AS empphoto, EP.gender AS empgender
					  , GRD.grade_name AS empgrade, EC.start_date AS empjoindate
					  , EC.emp_id AS empid, EC.employ_code, EC.position_id, EC.grade_code, POS.dept_id
					  , POS.position_id AS posid,ES.employmentstatus_name_#request.scookie.lang# emp_status, WL.worklocation_name,EC.created_date
					 FROM TEODEMPCOMPANY EC
					  INNER JOIN TEOMEMPPERSONAL EP ON EP.emp_id = EC.emp_id
					  LEFT JOIN TEOMPOSITION POS ON POS.position_id = EC.position_id 
					  LEFT JOIN TEOMPOSITION ORG ON ORG.position_id = POS.dept_id 
					  LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = EC.grade_code 
					  LEFT JOIN TEOMEMPLOYMENTSTATUS ES ON EC.employ_code = ES.employmentstatus_code
					   LEFT JOIN TEOMWORKLOCATION WL ON EC.work_location_code = WL.worklocation_code
					 WHERE EC.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					    AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
					  and (EC.start_date <= <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp"> 
					  and (EC.end_Date is null OR EC.end_Date > <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">))
					   order by EC.created_date desc
					</cfquery>
				</cfif>
	            <!--- TCK2107-0660305 --->
	        
				<!--- start : ENC51115-79853 --->
				<cfif qGetEmpDetail.recordcount eq 0>
					<cfquery name="qGetEmpDetail" datasource="#request.sdsn#">
					 SELECT distinct EP.full_name AS empname, EC.emp_no AS empno, POS.pos_name_#request.scookie.lang# AS emppos
					  , ORG.pos_name_#request.scookie.lang# AS orgunit, EP.photo AS empphoto, EP.gender AS empgender
					  , GRD.grade_name AS empgrade, EC.start_date AS empjoindate
					  , EC.emp_id AS empid, EC.employ_code, EC.position_id, EC.grade_code, POS.dept_id
					  , POS.position_id AS posid,ES.employmentstatus_name_#request.scookie.lang# emp_status, WL.worklocation_name,EC.created_date
					 FROM TEODEMPCOMPANY EC
					  INNER JOIN TEOMEMPPERSONAL EP ON EP.emp_id = EC.emp_id
					  LEFT JOIN TEOMPOSITION POS ON POS.position_id = EC.position_id 
					  LEFT JOIN TEOMPOSITION ORG ON ORG.position_id = POS.dept_id 
					  LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = EC.grade_code 
					  LEFT JOIN TEOMEMPLOYMENTSTATUS ES ON EC.employ_code = ES.employmentstatus_code
					   LEFT JOIN TEOMWORKLOCATION WL ON EC.work_location_code = WL.worklocation_code
					 WHERE EC.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					  and (EC.start_date <= <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp"> 
					  and (EC.end_Date is null OR EC.end_Date > <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">))
					   order by EC.created_date desc
					</cfquery>
        				
        				
				</cfif>
				<!--- end : ENC51115-79853 --->
	    	<cfreturn qGetEmpDetail>
	    </cffunction>
		
		
	    
	    <!---
	    <cffunction name="getLibComparison">
	        <cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="libtype" default="">
	        <cfargument name="libcode" default="">
	        
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT distinct C.full_name AS empname, D.pos_name_#request.scookie.lang# AS emppos, E.grade_name AS empgrade, A.achievement, H.reviewee_empid, B.emp_no AS empno
	           	<cfif ucase(libtype) eq "APPRAISAL">
	               	, LIB.appraisal_name AS lib_name
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	               	, LIB.objective_name AS lib_name
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	               	, LIB.competency_name AS lib_name
	            </cfif>
				FROM TPMDCPMLIBDETAIL A
	           	<cfif ucase(libtype) eq "APPRAISAL">
	            LEFT JOIN TPMDPERIODAPPLIB LIB ON LIB.appraisal_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	            LEFT JOIN TPMDPERIODOBJLIB LIB ON LIB.objective_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "COMPETENCE">
	            LEFT JOIN TPMDPERIODCOMPLIB LIB ON LIB.competence_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	            </cfif>
	            INNER JOIN TPMDCPMH 
	            	H ON H.request_no = A.request_no 
	                AND H.company_code = A.company_code
	                AND H.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	                
					<!--- nilainya ambil langsung dari form pake js--->
	                AND H.reviewee_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	                
				LEFT JOIN TEODEMPCOMPANY B 
	            	ON B.emp_id = H.reviewee_empid AND B.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMEMPPERSONAL C 
	            	ON C.emp_id = B.emp_id
				LEFT JOIN TEOMPOSITION D 
	            	ON D.position_id = B.position_id 
	            	AND D.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMJOBGRADE E 
	            	ON E.grade_code = B.grade_code 
	                AND E.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE A.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND A.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
	            ORDER BY A.achievement DESC
	        </cfquery>
	        <cfreturn qData>
	    </cffunction>
		--->
	    
	    <cffunction name="getAllReviewerData">
	    	<cfargument name="reqno" default="">
	        <cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="step" default="">
	        <cfargument name="libtype" default="APPRAISAL">
	        <cfargument name="libcode" default="">
			<cfargument name="notes" default="">
			 <!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">   
	         <!---  end :  ENC51115-79853 --->
			<cfif libtype eq 'APPRAISAL'>	
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT  APLIB.parent_path, APP.apprlib_code, APP.position_id FROM TPMDPERIODAPPRAISAL APP, TEODEMPCOMPANY COMP, TPMDPERIODAPPRLIB APLIB
					WHERE COMP.position_id = APP.position_id
					AND APLIB.period_code = APP.period_code
					AND APLIB.apprlib_code = APP.apprlib_code
					AND APP.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND COMP.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND APP.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY APP.apprlib_code
				</cfquery>
				<cfquery name="local.qCheck" datasource="#request.sdsn#">
					SELECT  EVALH.form_no FROM TPMDPERFORMANCE_EVALH EVALH 
					WHERE EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.apprlib_code))>
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
						SELECT  isnull(APPR.apprlib_code,APPLIB.apprlib_code) lib_code, APPLIB.appraisal_name_#request.scookie.lang# lib_name,
						    APPLIB.parent_code parent_code, APPLIB.iscategory iscategory, 
							APPLIB.parent_path parent_path, APPLIB.appraisal_depth lib_depth, 
							isnull(EVALD.weight,APPR.weight) weight, isnull(EVALD.target,APPR.target) target, isnull(EVALD.achievement,0) achievement, 
							isnull(EVALD.achievement,0) achievement
						FROM TPMDPERIODAPPRLIB APPLIB 
						<!--- LEFT JOIN TPMDPERIODAPPRAISAL APPR ON APPLIB.period_code = APPR.period_code AND APPLIB.company_code = APPR.company_code AND APPLIB.apprlib_code = APPR.apprlib_code AND APPLIB.reference_date = APPR.reference_date --->
						LEFT JOIN TPMDPERIODAPPRAISAL APPR ON APPLIB.period_code = APPR.period_code AND APPLIB.company_code = APPR.company_code AND APPLIB.apprlib_code = APPR.apprlib_code <!--- AND APPLIB.reference_date = APPR.reference_date --remove join or where reference_date --->
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON APPLIB.apprlib_code = EVALD.lib_code AND APPLIB.company_code = EVALD.company_code and EVALD.lib_code = APPR.apprlib_code
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code AND EVALH.period_code = APPR.period_code
						WHERE (APPR.position_id = '#qGetParent.position_id#' or APPR.position_id IS NULL)
						<cfif parentpath neq "">
							AND APPLIB.apprlib_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							AND 1 = 0
						</cfif>
						<cfif qCheck.recordcount>
							AND (EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR (APPLIB.iscategory='Y' AND EVALH.request_no IS NULL AND APPLIB.period_code =<cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						<cfelse>
							AND (EVALH.request_no IS NULL AND APPLIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						</cfif>	
						order by lib_depth,lib_code asc 
				</cfquery>
			<cfelseif libtype eq 'OBJECTIVE'>
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT  parent_path,kpilib_code,KPI.position_id FROM TPMDPERIODKPI KPI, TEODEMPCOMPANY COMP
					WHERE KPI.position_id = COMP.position_id
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND COMP.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY kpilib_code
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.kpilib_code))>
				<!---  <cfdump var="#parentpath#"> --->
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT  isnull(KPI.kpilib_code,KPILIB.kpilib_code) lib_code, isnull(KPI.kpi_name_en,KPILIB.kpi_name_en) lib_name,
							isnull(KPI.parent_code,KPILIB.parent_code) parent_code, isnull(KPI.iscategory,KPILIB.iscategory) iscategory, 
							isnull(KPI.parent_path,KPILIB.parent_path) parent_path, isnull(KPI.kpi_depth,KPILIB.kpi_depth) lib_depth, 
							isnull(EVALD.weight,KPI.weight) weight, isnull(EVALD.target,KPI.target) target, isnull(EVALD.achievement,0) achievement, isnull(EVALD.achievement,0) achievement
						FROM TPMDPERIODKPILIB KPILIB 
						LEFT JOIN TPMDPERIODKPI KPI ON KPILIB.period_code = KPI.period_code AND KPILIB.company_code = KPI.company_code AND KPILIB.kpilib_code = KPI.kpilib_code <!--- AND KPILIB.reference_date = KPI.reference_date --remove join or where reference_date  --->
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON KPILIB.kpilib_code = EVALD.lib_code AND KPILIB.company_code = EVALD.company_code
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code	
						WHERE (KPI.position_id = '#qGetParent.position_id#' or KPI.position_id IS NULL)
						<cfif parentpath neq "">
							AND KPILIB.kpilib_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							AND 1 = 0
						</cfif>
							AND ((EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR EVALH.request_no IS NULL AND KPILIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						order by lib_depth,lib_code asc 
				</cfquery>		
			<cfelseif libtype eq 'OBJECTIVEORG'>
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT  parent_path,kpilib_code,KPI.position_id FROM TPMDPERIODKPI KPI, TEODEMPCOMPANY COMP
					WHERE KPI.position_id = COMP.position_id
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND COMP.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY kpilib_code
				</cfquery>
				<cfquery name="local.qGetHeadDivKPI" datasource="#request.sdsn#">
					SELECT  DEPT.head_div 
					FROM TEOMPOSITION POS	  
						LEFT JOIN TEOMPOSITION DEPT ON POS.dept_id = DEPT.position_id AND POS.company_id = DEPT.company_id 	
						WHERE POS.position_id = <cfqueryparam value="#qGetParent.position_id#" cfsqltype="cf_sql_varchar">
						AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfquery name="local.qGetPosLogin" datasource="#request.sdsn#">
					SELECT distinct POS.position_id FROM TEODEMPCOMPANY COMPA
						INNER JOIN TEOMPOSITION POS ON COMPA.position_id = pos.position_id AND COMPA.company_id = pos.company_id
						WHERE COMPA.emp_id = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
						AND COMPA.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.kpilib_code))>
				<cfif qGetHeadDivKPI.head_div eq qGetPosLogin.position_id>
					<cfset local.editable = 1>
				<cfelse>
					<cfset local.editable = 0>
				</cfif>
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT  isnull(KPI.kpilib_code,KPILIB.kpilib_code) lib_code, isnull(KPI.kpi_name_en,KPILIB.kpi_name_en) lib_name,
							isnull(KPI.parent_code,KPILIB.parent_code) parent_code, isnull(KPI.iscategory,KPILIB.iscategory) iscategory, 
							isnull(KPI.parent_path,KPILIB.parent_path) parent_path, isnull(KPI.kpi_depth,KPILIB.kpi_depth) lib_depth, 
							isnull(EVALD.weight,KPI.weight) weight, isnull(EVALD.target,KPI.target) target, isnull(EVALD.achievement,0) achievement, isnull(EVALD.achievement,0) achievement,
							'#editable#' editable
						FROM TPMDPERIODKPILIB KPILIB 
						LEFT JOIN TPMDPERIODKPI KPI ON KPILIB.period_code = KPI.period_code AND KPILIB.company_code = KPI.company_code AND KPILIB.kpilib_code = KPI.kpilib_code AND <!--- KPILIB.reference_date = KPI.reference_date --remove join or where reference_date ---> 
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON KPILIB.kpilib_code = EVALD.lib_code AND KPILIB.company_code = EVALD.company_code
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code	
						WHERE (KPI.position_id = '#qGetParent.position_id#' or KPI.position_id IS NULL)
						<cfif parentpath neq "">
							AND KPILIB.kpilib_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							AND 1 = 0
						</cfif>
							AND ((EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR EVALH.request_no IS NULL AND KPILIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
						order by lib_depth,lib_code asc 
				</cfquery>
			<cfelseif libtype eq 'COMPETENCY'>
				<cfquery name="local.qGetParent" datasource="#request.sdsn#">
					SELECT distinct COM.parent_path,JT.competence_code
					FROM TEODEMPCOMPANY COMPA
						INNER JOIN TEOMPOSITION POS ON COMPA.position_id = pos.position_id AND COMPA.company_id = pos.company_id
						INNER JOIN TPMRCOMPETENCEJT JT ON POS.jobtitle_code = JT.jobtitle_code
						INNER JOIN TPMMCOMPETENCE COM ON JT.competence_code = COM.competence_code
						WHERE COMPA.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
						AND COMPA.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfquery name="local.qCheck" datasource="#request.sdsn#">
					SELECT distinct EVALH.form_no FROM TPMDPERFORMANCE_EVALH EVALH 
					WHERE EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset local.parentpath = ValueList(qGetParent.parent_path)>
				<cfset parentpath = ListAppend(parentpath,ValueList(qGetParent.competence_code))>
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT distinct competence_code lib_code, COMPLIB.competence_name_en lib_name,order_no,
							COMPLIB.parent_code, COMPLIB.iscategory, 
							COMPLIB.parent_path,COMPLIB.competence_depth lib_depth, 
							isnull(EVALD.weight,0) weight, isnull(EVALD.target,0) target, isnull(EVALD.achievement,0) achievement, isnull(EVALD.achievement,0) achievement,isnull(EVALD.score,0) score, EVALD.notes,
							EVALD.reviewer_empid
						FROM TPMMCOMPETENCE COMPLIB 
						LEFT JOIN TPMDPERFORMANCE_EVALD EVALD ON COMPLIB.competence_code = EVALD.lib_code	
						LEFT JOIN TPMDPERFORMANCE_EVALH EVALH ON EVALD.form_no = EVALH.form_no AND EVALD.company_code = EVALH.company_code	AND EVALD.reviewer_empid = EVALH.reviewer_empid		
						<cfif parentpath neq "">
							WHERE COMPLIB.competence_code IN (#ListQualify(parentpath,"'")#)
						<cfelse>
							WHERE 1 = 0
						</cfif>
							AND ((EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
							AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
							<!--- AND EVALH.reviewer_empid = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar"> --->
							AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
							OR EVALH.request_no IS NULL)
						order by lib_depth,order_no asc 
				</cfquery>	
			<cfelseif libtype eq "COMPONENT">
				<cfquery name="local.qComponentData" datasource="#request.sdsn#">
					SELECT  distinct EVALD.score
					FROM TPMDPERFORMANCE_EVALD EVALD, TPMDPERFORMANCE_EVALH EVALH 
					WHERE EVALH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND EVALH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND EVALD.reviewer_empid  = <cfqueryparam value="#reviewer#" cfsqltype="cf_sql_varchar">
					AND EVALH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND EVALD.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND EVALD.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">	
					AND EVALH.reviewer_empid = EVALD.reviewer_empid
					AND EVALH.form_no = EVALD.form_no
				</cfquery>	
			<cfelse>
				<cfset local.qComponentData = 0>
			</cfif>
			<!--- <cf_sfwritelog dump="qComponentData" prefix="RanggaSFPer"> --->
	        <cfreturn qComponentData>
	    </cffunction>
	    
	    <!--- Task Function --->
	    <cffunction name="TaskListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">    <!---  added by :  ENC51115-79853 --->
	        <cfquery name="local.qGetTaskListing" datasource="#request.sdsn#">
	        	SELECT  TK.task_code, EP.full_name AS asignee_name, TK.task_desc, TK.priority, TK.status, TK.startdate, TK.duedate, GBY.full_name AS givenby, TK.status_task, TK.completion_date, created_task
				FROM TPMMPERIOD PR, TPMDTASK TK INNER JOIN TEOMEMPPERSONAL GBY	ON GBY.emp_id = TK.created_task
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = TK.assignee 
					AND TK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND TK.assignee = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
				WHERE TK.duedate >= PR.period_startdate
				AND TK.duedate <= PR.period_enddate
				AND TK.company_code = PR.company_code
				AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
			<!--- <cf_sfwritelog dump="qGetTaskListing" prefix="qGetTaskListing_">--->
	        <cfreturn qGetTaskListing>
	    </cffunction>

	    <!--- Feedback Function --->
	    <cffunction name="FeedbackListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">    <!---  added by :  ENC51115-79853 --->
	        <cfquery name="local.qGetFBListing" datasource="#request.sdsn#">
			    SELECT  FB.feedback_code, EP.full_name AS feedbackby, FB.feedback_type, FB.feedback_desc, FB.severity_level, FB.created_date, created_feedback
				FROM TPMMPERIOD PR, TPMDFEEDBACK FB INNER JOIN TEOMEMPPERSONAL EP
					ON EP.emp_id = FB.created_feedback
					AND FB.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND FB.feedback_for = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
				WHERE FB.created_date >= PR.period_startdate
				AND FB.created_date <= PR.period_enddate
				AND FB.company_code = PR.company_code
				AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qGetFBListing>
	    </cffunction>

	    <!--- Evaluation History Tab Function --->
	    <cffunction name="EvaluationHistListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">		
			 <!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">  
			
            <cfset LOCAL.InitVarCountDeC = 2><!---override di hardcode 2 decimal seperti di overallscore, tadinya dr REQUEST.InitVarCountDeC--->
			 <!---  end :  ENC51115-79853 --->
	        <cfquery name="local.qGetEvHistListing" datasource="#request.sdsn#">
	        	SELECT  PER.period_name_#request.scookie.lang# AS formname, PER.period_startdate, PER.period_enddate
					, POS.pos_name_#request.scookie.lang# AS emppos, GRD.grade_name AS empgrade, STS.employmentstatus_name_#request.scookie.lang# AS empstatus
					, ROUND(PMH.final_score,#InitVarCountDeC#) AS empscore <!---BUG50415-42293--->
					, PMH.final_conclusion AS empconclusion, PMH.reference_date startdate
				FROM TPMDPERFORMANCE_FINAL PMH
					LEFT JOIN TPMMPERIOD PER ON PER.period_code = PMH.period_code AND PER.company_code = PMH.company_code
	                LEFT JOIN TEOMPOSITION POS ON POS.position_id = PMH.reviewee_posid AND POS.company_id = #request.scookie.coid#
					LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = PMH.reviewee_grade AND GRD.company_id = #request.scookie.coid#
					LEFT JOIN TEOMEMPLOYMENTSTATUS STS ON STS.employmentstatus_code = PMH.reviewee_employcode
				WHERE PMH.reviewee_empid = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
					AND PMH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					<!--- untuk semua period --->
	                <!---
					AND PMH.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					--->
					ORDER BY PMH.reference_date DESC, PER.period_name_#request.scookie.lang# ASC
	        </cfquery>
	        <cfreturn qGetEvHistListing>
	    </cffunction>
	    
	    <cffunction name="AwardsHistListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			 <!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">   
			 <!---  end :  ENC51115-79853 --->
	        <cfquery name="local.qGetAwdHistListing" datasource="#request.sdsn#">
	        	SELECT  POS.pos_name_#request.scookie.lang# AS emppos
	            	, MA.achievement_name_#request.scookie.lang# AS awardname
	            	, EA.refno AS awardno
	                , EA.refdt AS awarddate
	                , EA.achievement_letter AS letterno
	                , EA.achievement_certificate AS certificateno
				FROM TPMMPERIOD PR, TCATEMPACHIEVEMENTHISTORY EA
					LEFT JOIN TCAMAWARD MA ON MA.achievement_code =  EA.achievement_code 
	                LEFT JOIN TEOMPOSITION POS ON POS.position_id = EA.position_id AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE EA.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					AND EA.emp_id = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
					AND EA.refdt >= PR.period_startdate
					AND EA.refdt <= PR.period_enddate
					AND PR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qGetAwdHistListing>
	    </cffunction>

	    <cffunction name="DiscHistListing">
	    	<cfargument name="asigneeId" default="">
			<cfargument name="periodcode" default="">
			<!---  start :  ENC51115-79853 --->
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">   
			<cfargument name="varcoid" default="#request.scookie.coid#" required="No">   
			 <!---  end :  ENC51115-79853 --->
	        <cfquery name="local.qGetDiscHistListing" datasource="#request.sdsn#">
	        	SELECT  POS.pos_name_#request.scookie.lang# AS emppos
	            	, ED.refno AS discno
	                , ED.refdt AS discdate
	                , MD.disciplines_name_#request.scookie.lang# AS discname
	                , ED.startdt AS startdate
	                , ED.enddt AS enddate
	                , '' AS status
	                <cfif request.dbdriver eq "MSSQL">
					,  CASE WHEN datediff(day,ED.startdt,getdate())<0 THEN 'Inactive' WHEN datediff(day,ED.startdt,getdate())>=0 THEN CASE WHEN datediff(day,getdate(),ED.enddt) <0 THEN 'Expired' WHEN datediff(day,getdate(),ED.enddt) >=0 THEN 'Active ['+convert(varchar,datediff(day,getdate(),ED.enddt))+']' END END expired
					<cfelse>
					,  CASE WHEN TIMESTAMPDIFF(day,ED.startdt,now())<0 THEN 'Inactive' WHEN TIMESTAMPDIFF(day,ED.startdt,now())>=0 THEN CASE WHEN TIMESTAMPDIFF(day,now(),ED.enddt) <0 THEN 'Expired' WHEN TIMESTAMPDIFF(day,now(),ED.enddt) >=0 THEN 'Active ['||convert(TIMESTAMPDIFF(day,now(),ED.enddt),char)||']' END END expired
					</cfif>
	                , ED.letter_no AS letterno
				FROM TPMMPERIOD PR, TCATDISCIPLINESHISTORY ED
					LEFT JOIN TCAMDISCIPLINE MD ON MD.disciplines_code = ED.disciplines_code
					LEFT JOIN TEOMPOSITION POS ON POS.position_id = ED.position_id AND POS.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE ED.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					AND ED.emp_id = <cfqueryparam value="#asigneeId#" cfsqltype="cf_sql_varchar">
					AND ED.startdt <= PR.period_enddate
					AND ED.enddt >= PR.period_startdate
					AND PR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND PR.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qGetDiscHistListing>
	    </cffunction>
		
		<!--- Return Score Range --->
	    <cffunction name="ScoreRange">
	    	<cfargument name="periodcode" default="">
			<cfargument name="type" default="task">
			
	        <cfquery name="local.qGetScore" datasource="#request.sdsn#">
	        	SELECT distinct scoredet_value, scoredet_order 
				FROM TGEDSCOREDET	WHERE score_code = (SELECT score_type FROM TPMMPERIOD 
					WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
				ORDER BY scoredet_order
	        </cfquery>
			
			<cfset local.score = "">
			<cfset score = listappend(score,listfirst(valuelist(qGetScore.scoredet_value)))>
			<cfset score = listappend(score,listlast(valuelist(qGetScore.scoredet_value)))>
	        <cfreturn score>
	    </cffunction>
		
		<!--- Return Final Score --->
	    <cffunction name="FinalScore">
	    	<cfargument name="periodcode" default="">
			<cfargument name="type" default="task">
			<cfargument name="fscore" default="">
			<cfargument name="refdate" default="">
			
			<cfquery name="local.qCekLookUp" datasource="#request.sdsn#">
				SELECT  lookup_code FROM TPMDPERIODCOMPONENT 
				WHERE component_code = <cfqueryparam value="#type#" cfsqltype="cf_sql_varchar">
				AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				<!--- AND reference_date = <cfqueryparam value="#refdate#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
			</cfquery>
			
			<cfif qCekLookUp.recordcount>
		        <cfquery name="local.qGetSymbol" datasource="#request.sdsn#">
		        	SELECT symbol, lookup_code FROM TPMMLOOKUP
					WHERE lookup_code = <cfqueryparam value="#qCekLookUp.lookup_code#" cfsqltype="cf_sql_varchar">
		        </cfquery>

				<cfset local.finalscore = fscore>
				<cfif qGetSymbol.recordcount>
					<cfquery name="local.qScore" datasource="#request.sdsn#">
			        	SELECT lookup_score, lookup_value FROM TPMDLOOKUP	WHERE lookup_code = <cfqueryparam value="#qGetSymbol.lookup_code#" cfsqltype="cf_sql_varchar">
						order by lookup_value
			        </cfquery>
					
					<cfset local.ctr = 0>
					<cfloop query="qScore">
						<cfset ctr = ctr + 1>
						<cfif qGetSymbol.symbol eq 'LT'>
							<cfif fscore lt lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'LTE'>
							<cfif fscore lte lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'SYM'>
							<cfif fscore eq lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'GT'>
							<cfif fscore gt lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						<cfelseif qGetSymbol.symbol eq 'GTE'>
							<cfif fscore gte lookup_value>
								<cfset finalscore = lookup_score>
								<cfbreak>
							<cfelseif ctr eq qScore.recordcount>
								<cfset finalscore = lookup_score>
								<cfbreak>
							</cfif>
						</cfif>
					</cfloop>
					<cfset VarScore.fscore = fscore>
					<cfset VarScore.taskscore = finalscore>
				<cfelse>
					<cfset VarScore.fscore = round(fscore)>
					<cfset VarScore.taskscore = round(finalscore)>
				</cfif>
			<cfelse>
				<cfset VarScore.fscore = round(fscore)>
				<cfset VarScore.taskscore = round(fscore)>
			</cfif>
			
	        <cfreturn VarScore>
	    </cffunction>
		
		<cffunction name="getScoring">
			<cfargument name="periodcode" default="">
			<cfquery name="local.qScoring" datasource="#request.sdsn#">
				SELECT distinct scoredet_value, scoredet_mask, scoredet_desc ,scoredet_order
				FROM TGEDSCOREDET	WHERE score_code = (SELECT score_type FROM TPMMPERIOD 
					WHERE period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">)
				ORDER BY scoredet_order
			</cfquery>
			<cfreturn qScoring>
		</cffunction>
	    
	   <cffunction name="cekOrgPersKPI">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="refdate" default="">
	    	<cfargument name="empid" default="">
	    	<cfargument name="posid" default="">
	        <!---  start :  ENC51115-79853 --->
			<cfargument name="varcoid" default="#request.scookie.coid#">
	    	<cfargument name="varcocode" default="#request.scookie.cocode#">
			<!---  end :  ENC51115-79853 --->
	        <cfset Local.listOrgUnit = "">
	        
	        <cfquery name="local.qCekIfPlanned" datasource="#request.sdsn#">
	        	SELECT CASE WHEN plan_startdate IS NULL THEN 0 ELSE 1 END useplan 
	            FROM TPMMPERIOD
				WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfif qCekIfPlanned.useplan>
		        <cfquery name="local.qCekIfUsed" datasource="#request.sdsn#">
		        	SELECT component_code FROM TPMDPERIODCOMPONENT
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		        </cfquery>
		        <cfset local.lstUsed = valuelist(qCekIfUsed.component_code)>

		        <cfset local.strckRet = structnew()>
		       	<cfset strckRet["perskpi"] = false>
	    	   	<cfset strckRet["orgkpi"] = true>
	        
		        <!--- cek PERSKPI --->
				 <cfquery name="Local.qCheckPersKPI" datasource="#request.sdsn#">
					SELECT  PH.request_no, PH.reviewee_unitpath FROM TPMDPERFORMANCE_PLANH PH
					INNER JOIN TPMDPERFORMANCE_PLAND PD
						ON PD.form_no = PH.form_no
						AND PD.company_code = PH.company_code
					WHERE
						PH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
						AND PH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
                     order by PH.created_date desc
		        </cfquery>
				 <cfquery name="local.qCekPersReq" datasource="#request.sdsn#">
					SELECT status FROM TCLTREQUEST 
	        	    WHERE req_type = 'PERFORMANCE.PLAN'
	            		AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		                AND req_no = <cfqueryparam value="#qCheckPersKPI.request_no#" cfsqltype="cf_sql_varchar">
	    	    </cfquery>
		        <cfquery name="Local.qCheckPersKPI" datasource="#request.sdsn#">
					SELECT  PH.request_no, PH.reviewee_unitpath FROM TPMDPERFORMANCE_PLANH PH
					INNER JOIN TPMDPERFORMANCE_PLAND PD
						ON PD.form_no = PH.form_no
						AND PD.company_code = PH.company_code
					WHERE
						<cfif listfindnocase("3,9",qCekPersReq.status) eq 0>
						PH.isfinal = 1 AND
						</cfif>
						 PH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
						AND PH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
                     order by PH.created_date desc
		        </cfquery>
		   
		      
			
		        <cfif listfindnocase("3,9",qCekPersReq.status)>
	    	    	<cfset strckRet["perskpi"] = true>
	            
					<!---<cfset listOrgUnit = qCheckPersKPI.reviewee_unitpath>--->
		            <cfquery name="local.qGetDeptId" datasource="#request.sdsn#">
		            	SELECT DISTINCT dept_id FROM TEOMPOSITION
						WHERE position_id = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_integer">
						AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		            </cfquery>
	    	        <cfset listOrgUnit = qGetDeptId.dept_id>
		        </cfif>

		        <!--- cek ORGKPI --->
		        <cfset local.listValidOrgUnit = "">
	    	    <cfloop list="#listOrgUnit#" index="local.orgunitidx">
	        	<cfif orgunitidx neq 0>
	        	
					<cfset local.listValidOrgUnit = listappend(listValidOrgUnit,orgunitidx)>
		   	    	<cfset strckRet["#orgunitidx#"] = false>
	            
			        <cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			        	SELECT DISTINCT request_no FROM TPMDPERFORMANCE_PLANKPI
	    		        WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	        		    	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
							AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        </cfquery>
					<cfquery name="local.qCekOrgReq" datasource="#request.sdsn#">
						SELECT DISTINCT status FROM TCLTREQUEST 
			            WHERE req_type = 'PERFORMANCE.PLAN'
	   			        	AND company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
	       			        AND req_no = <cfqueryparam value="#qCheckOrgKpi.request_no#" cfsqltype="cf_sql_varchar">
			        </cfquery>
					
			        <cfif listfindnocase("3,9",qCekOrgReq.status)>
						<cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			    	    	SELECT DISTINCT evalkpi_status FROM TPMDPERFORMANCE_EVALKPI
			        	    WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
		    	        		AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
								AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        	</cfquery>
						
		    	        <cfif qCheckOrgKpi.evalkpi_status eq 3>
		   	    	    	<cfset strckRet["#orgunitidx#"] = true>
		        	    </cfif>
			        </cfif>
	            
		            <cfif not strckRet["#orgunitidx#"]>
			            <cfset strckRet["orgkpi"] = false>
		            </cfif>
		        </cfif>
		        </cfloop>
	        
		        <cfset strckRet["listorgunit"] = listValidOrgUnit>
		        <!--- VALIDATE NEW UI --->
		        <cfset flagnewui = "#REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE#">
		    
	    	    <cfif not strckRet["perskpi"] and listfindnocase(lstUsed,"persKPI")>
		    	    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSPersonal Objective is not yet set in planning",true)>
		    	    <cfif flagnewui eq 0>
    		    		<cfoutput>
    			        	<script>
    							alert("#LOCAL.SFLANG#");
    							//console.log('yan #strckRet["perskpi"]#')
    							maskButton(false);
    						</script>
    			        </cfoutput>
			        <cfelse>
			            <cfset data = {msg="#SFLANG#", success="0"}>
                        <cfset serializedStr = serializeJSON(data)>
            		    <cfoutput>
            		        #serializedStr#
            		    </cfoutput>
            		    <CF_SFABORT>
		            </cfif>
				    <cfreturn false>
	    	    <cfelseif not strckRet["orgkpi"] and listfindnocase(lstUsed,"orgKPI")>
			        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSOrg Unit Objective must be verified before",true)>
			        <cfif flagnewui eq 0>
    			    	<cfoutput>
    	    		    	<script>
    							alert("#LOCAL.SFLANG#");
    							//console.log('yan #strckRet["orgkpi"]#')
    							maskButton(false);
    						</script>
    			        </cfoutput>
			        <cfelse>
			            <cfset data = {msg="#SFLANG#", "success"="0"}>
                        <cfset serializedStr = serializeJSON(data)>
            		    <cfoutput>
            		        #serializedStr#
            		    </cfoutput>
            		    <CF_SFABORT>
			        </cfif>
		            <cfreturn false> 
				
		        <cfelse>
		            <cfreturn true>
		        </cfif>
	        <cfelse>
	            <cfreturn true>
			</cfif>
	    </cffunction>
	    <cffunction name="cekOrgPersKPIBeforeSubmit">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="refdate" default="">
	    	<cfargument name="empid" default="">
	    	<cfargument name="posid" default="">
	        <!---  start :  ENC51115-79853 --->
			<cfargument name="varcoid" default="#request.scookie.coid#">
	    	<cfargument name="varcocode" default="#request.scookie.cocode#">
			<!---  end :  ENC51115-79853 --->
	        <cfset Local.listOrgUnit = "">
	        
	        <cfquery name="local.qCekIfPlanned" datasource="#request.sdsn#">
	        	SELECT CASE WHEN plan_startdate IS NULL THEN 0 ELSE 1 END useplan 
	            FROM TPMMPERIOD
				WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        
	        
	        <cfif qCekIfPlanned.useplan>
		        <cfquery name="local.qCekIfUsed" datasource="#request.sdsn#">
		        	SELECT component_code FROM TPMDPERIODCOMPONENT
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		        </cfquery>
		        <cfset local.lstUsed = valuelist(qCekIfUsed.component_code)>

		        <cfset local.strckRet = structnew()>
		       	<cfset strckRet["perskpi"] = false>
	    	   	<cfset strckRet["orgkpi"] = true>
	        
		        <!--- cek PERSKPI --->
				
	    	    <cfquery name="Local.qCheckPersKPI0" datasource="#request.sdsn#">
					SELECT <cfif request.dbdriver eq "MSSQL"> TOP 1 </cfif> PH.request_no FROM TPMDPERFORMANCE_PLANH PH
					WHERE
						PH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
						AND PH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
                    ORDER by PH.created_date desc <cfif request.dbdriver eq "MYSQL"> LIMIT 1 </cfif>
		        </cfquery>
				
				 <cfquery name="local.qCekPersReq" datasource="#request.sdsn#">
					SELECT status FROM TCLTREQUEST WHERE req_type = 'PERFORMANCE.PLAN'
	            		AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		                AND req_no = <cfqueryparam value="#qCheckPersKPI0.request_no#" cfsqltype="cf_sql_varchar">
	    	    </cfquery>
				
		        <cfquery name="Local.qCheckPersKPI" datasource="#request.sdsn#">
					SELECT  PH.request_no, PH.reviewee_unitpath FROM TPMDPERFORMANCE_PLANH PH
					INNER JOIN TPMDPERFORMANCE_PLAND PD
						ON PD.form_no = PH.form_no
						AND PD.company_code = PH.company_code
					WHERE
						<cfif listfindnocase("3,9",qCekPersReq.status) eq 0>
						PH.isfinal = 1 AND
						</cfif>
						 PH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
						AND PH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
                     order by PH.created_date desc
		        </cfquery>
				 <cfif listfindnocase("3,9",qCekPersReq.status)>
	    	    	<cfset strckRet["perskpi"] = true>
	            
					<!---<cfset listOrgUnit = qCheckPersKPI.reviewee_unitpath>--->
		            <cfquery name="local.qGetDeptId" datasource="#request.sdsn#">
		            	SELECT DISTINCT dept_id FROM TEOMPOSITION
						WHERE position_id = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_integer">
						AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		            </cfquery>
	    	        <cfset listOrgUnit = qGetDeptId.dept_id>
		        </cfif>

		        <!--- cek ORGKPI --->
		        <cfset local.listValidOrgUnit = "">
	    	   <cfif len(listOrgUnit) neq 0 >
		             <cfloop list="#listOrgUnit#" index="local.orgunitidx">
	        	    <cfif orgunitidx neq 0>
	        	
					<cfset local.listValidOrgUnit = listappend(listValidOrgUnit,orgunitidx)>
		   	    	<cfset strckRet["#orgunitidx#"] = false>
	            
			        <cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			        	SELECT DISTINCT request_no FROM TPMDPERFORMANCE_PLANKPI
	    		        WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	        		    	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
							AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        </cfquery>
					<cfquery name="local.qCekOrgReq" datasource="#request.sdsn#">
						SELECT DISTINCT status FROM TCLTREQUEST 
			            WHERE req_type = 'PERFORMANCE.PLAN'
	   			        	AND company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer">
	       			        AND req_no = <cfqueryparam value="#qCheckOrgKpi.request_no#" cfsqltype="cf_sql_varchar">
			        </cfquery>
					
			        <cfif listfindnocase("3,9",qCekOrgReq.status)>
						<cfquery name="local.qCheckOrgKpi" datasource="#request.sdsn#">
			    	    	SELECT DISTINCT evalkpi_status FROM TPMDPERFORMANCE_EVALKPI
			        	    WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
		    	        		AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
								AND orgunit_id = <cfqueryparam value="#orgunitidx#" cfsqltype="cf_sql_integer">
			        	</cfquery>
						
		    	        <cfif qCheckOrgKpi.evalkpi_status eq 3>
		   	    	    	<cfset strckRet["#orgunitidx#"] = true>
		        	    </cfif>
			        </cfif>
	            
		            <cfif not strckRet["#orgunitidx#"]>
			            <cfset strckRet["orgkpi"] = false>
		            </cfif>
		        </cfif>
		        </cfloop>
	            <cfelse>
	                <cfset strckRet["orgkpi"] = false>
		        </cfif>
	        
		        <cfset strckRet["listorgunit"] = listValidOrgUnit>
		        <!--- VALIDATE NEW UI --->
		        <cfset flagnewui = "#REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE#">
		    
                <cfif not strckRet["perskpi"] and listfindnocase(lstUsed,"persKPI")>
		    	    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSPersonal Objective is not yet set in planning",true)>
    		    	<cfoutput>
    			        <script>
    						alert("#LOCAL.SFLANG#");
    				
    					</script>
    			      </cfoutput>
			     
				  
			        </cfif>
			         <cfif not strckRet["orgkpi"] and listfindnocase(lstUsed,"orgKPI")>
	    	    
			        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSOrg Unit Objective must be verified before",true)>
			        
    			    	<cfoutput>
    	    		    	<script>
    							alert("#LOCAL.SFLANG#");
    					
    						</script>
    			        </cfoutput>
			      
		        </cfif>
		            <cfreturn false> 
				

	        <cfelse>
	            <cfreturn true>
			</cfif>
	    </cffunction>
	   	    

	    <cffunction name="ValidateForm" access="public" returntype="boolean">
			<cfargument name="iAction" type="numeric" required="yes">
			<cfargument name="strckFormData" type="struct" required="yes">
	    	<cfparam name="action" default="0">
	    	<cfparam name="sendtype" default="0">
	        
	       	<cfset local.headstatus = 0>
	        <cfif sendtype eq 'directfinal'>
	        	<cfset headstatus = 1/>
	        <cfelseif action eq 'sendtoapprover' or sendtype eq 'next'>
	        	<cfset headstatus = 1/>
			<cfelseif action eq 'draft'>
	        	<cfset headstatus = 1/>
	        </cfif>

			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
				SELECT  grade_code, employ_code, position_id 
				FROM TEODEMPCOMPANY 
				WHERE emp_id = <cfqueryparam value="#strckFormData.requestfor#" cfsqltype="cf_sql_varchar">
				and status = 1
			    AND company_id =  <cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_integer">
			</cfquery>
			<cfif qDetailReviewee.recordcount eq 0>
    			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
    				SELECT  grade_code, employ_code, position_id 
    				FROM TEODEMPCOMPANY 
    				WHERE emp_id = <cfqueryparam value="#strckFormData.requestfor#" cfsqltype="cf_sql_varchar">
    				and status = 1
    			</cfquery>
			</cfif>
	        
	        <cfset local.retvar = true>
			
	        <cfif (listfindnocase(ucase(listPeriodComponentUsed),"ORGKPI") or listfindnocase(ucase(listPeriodComponentUsed),"PERSKPI")) and headstatus eq 1>
	            <cfset retvar = cekOrgPersKPI(FORM.period_code,strckFormData.reference_date,strckFormData.requestfor,qDetailReviewee.position_id,REQUEST.SCOOKIE.COID,REQUEST.SCOOKIE.COCODE)> 
	        </cfif>
	        
    		<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()> 
    		
			<cfreturn retvar>
		</cffunction>
		 <cffunction name="qDataUploadAtt">
        
		    <cfargument name="formno" default="">
            <cfargument name="kpitype" default="">
            <cfargument name="performance_period" default="">
            <cfargument name="empid" default="">
            <cfargument name="reviewee_empid" default="">
            
            <cfquery name="LOCAL.qDataUpload" datasource="#request.sdsn#">
            SELECT TV.form_no,TV.file_attachment,a.full_name,a.emp_id
            FROM TPMDPERF_EVALATTACHMENT TV
            INNER JOIN teomemppersonal a ON A.emp_id = TV.reviewer_empid
            WHERE 
            TV.period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND TV.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND TV.lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND TV.reviewer_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                AND TV.reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
				order by TV.created_date desc
            </cfquery>
            
            <cfreturn qDataUpload>
        </cffunction>
		  <cffunction name="checkUploadAtt">
        
		    <cfargument name="formno" default="">
            <cfargument name="kpitype" default="">
            <cfargument name="performance_period" default="">
            <cfargument name="empid" default="">
            <cfargument name="reviewee_empid" default="">
            
            <cfquery name="LOCAL.qGetExistingEvalTech" datasource="#request.sdsn#">
            SELECT form_no,file_attachment
            FROM TPMDPERF_EVALATTACHMENT 
            WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
                AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfreturn qGetExistingEvalTech>
        </cffunction>
        
        <cffunction name="deleteAttachment">
            <cfparam name="formno" default="">
            <cfparam name="kpitype" default="">
            <cfparam name="idxattachment" default="">        
            <cfparam name="performance_period" default="">     
            <cfparam name="empid" default = "#request.scookie.user.empid#" >
            <cfparam name="reviewee_empid" default="">
            <cfparam name="FileName" default="">
			<cfquery name="LOCAL.qUpdateEvalAttch" datasource="#request.sdsn#" result="LOCAL.vresult">
				DELETE FROM  TPMDPERF_EVALATTACHMENT 
				WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
				AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
				AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
				AND file_attachment = <cfqueryparam value="#FileName#" cfsqltype="cf_sql_varchar">
				AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
				AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
     
        <CF_SFUPLOAD ACTION="DELETE" CODE="evalattachment" FILENAME="#FileName#" output="xlsuploadedDelete">
            <cfoutput>
               <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSAttachment Deleted",true)>
                <script>
                    alert("#SFLANG#");
                 var retContentAtt = `
                     <input id="inp_fileupload_#idxattachment#" name="inp_fileupload_#idxattachment#" type="File" value="" onfocus="" size="30" maxlength="50" style="width: 200px;float: left;" onchange="" title="">
	                    <a id="btn_fileupload_attachment_#idxattachment#" href="##" class="button" style="font-size: smaller;box-shadow: 0px 0px 5px ##919191 !important;" onclick="startUploadAttach#kpitype#('inp_fileupload_#idxattachment#','#idxattachment#')" >
                            <span>Upload</span>
                        </a>`;
                
                parent.$("[id=upload_attach_#kpitype#]").html(retContentAtt);
                </script>
            </cfoutput>
        </cffunction>
          <!--- <cffunction name="deleteAttachment">
        <cfparam name="formno" default="">
        <cfparam name="kpitype" default="">
        <cfparam name="idxattachment" default="">        
        <cfparam name="performance_period" default="">     
        <cfparam name="empid" default = "#request.scookie.user.empid#" >
        <cfparam name="FileName" default="">
        
     <cfquery name="LOCAL.qUpdateEvalAttch" datasource="#request.sdsn#" result="LOCAL.vresult">
            UPDATE  TPMDPERF_EVALATTACHMENT 
            SET file_attachment = NULL
             WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
                AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND file_attachment = <cfqueryparam value="#FileName#" cfsqltype="cf_sql_varchar">
        </cfquery>
     
        <CF_SFUPLOAD ACTION="DELETE" CODE="evalattachment" FILENAME="#FileName#" output="xlsuploadedDelete">
 
       <cfoutput>
            <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSAttachment Deleted",true)>
            <script>
                  alert('Attachment Deleted');
              
            </script>
           <script>
                alert('#SFLANG#');
                var retContentAtt = '
                     <input id="inp_fileupload_#idxattachment#" name="inp_fileupload_#idxattachment#" type="File" value="" onfocus="" size="30" maxlength="50" style="width: 200px;float: left;" onchange="" title="">
	                    <a id="btn_fileupload_attachment_#idxattachment#" href="##" class="button" style="font-size: smaller;box-shadow: 0px 0px 5px ##919191 !important;" onclick="startUploadAttach('inp_fileupload_#idxattachment#','#idxattachment#')" >
                            <span>Upload</span>
                        </a>';
                
                parent.$("[id=upload_attach_#kpitype#]").html(retContentAtt);
            </script>
        </cfoutput>
    </cffunction>--->
        <cffunction name="uploadAttachment">
        
		<cfparam name="formno" default="">
        <cfparam name="kpitype" default="">
        <cfparam name="inp_uploadfield" default="">
        <cfparam name="idxattachment" default="">
        <cfparam name="performance_period" default="">
        <cfparam name="empid" default="request.scookie.user.empid">
        <cfparam name="reviewee_empid" default="">
        
       <!--- <cfdump var="#formno#">
        <cfdump var="#kpitype#">
        <cfdump var="#inp_uploadfield#">
        <cfdump var="#idxattachment#">
        <cfdump var="#performance_period#">
        <cfdump var="#empid#">--->
        

        <cfparam name="evaldateattachment_#idxattachment#" default="">
        <cfset LOCAL.currmondateattachment = Evaluate('evaldateattachment_#idxattachment#') >

        <cfset LOCAL.renameFile="#formno#_#idxattachment#_#empid#">
        <cfset LOCAL.subfolderpath = dateformat(now(),'YYYY#APPLICATION.OSSPT#MM') >
        <cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("JSExtension of the uploaded file was not accepted",true)>
        <CF_SFUPLOAD ACTION="UPLOAD" CODE="evalattachment" FILEFIELD="fileupload_#idxattachment#" REWRITE="YES"  SUBFOLDER="#subfolderpath#" output="xlsuploaded">
   
      		<cfset  LOCAL.file_name_save = xlsuploaded.serverfile />
      	
         <cfset filetemp = replace(file_name_save,"/",",","All")>
       
        <cfset namefile =ListLast(filetemp)>
       
        <cfquery name="LOCAL.qGetExistingEvalTech" datasource="#request.sdsn#">
            SELECT form_no
            FROM TPMDPERF_EVALATTACHMENT 
            WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
                AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
                
        </cfquery>
     
        	
        <cfif qGetExistingEvalTech.recordcount eq 0>
		  <cfquery name="local.insertevalattachment" datasource="#request.sdsn#" result="local.req">
                INSERT INTO TPMDPERF_EVALATTACHMENT  
                (form_no,company_id,lib_type,reviewer_empid,period_code,file_attachment,created_by,created_date,modified_by,modified_date,reviewee_empid)
                VALUES (
                <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#file_name_save#" cfsqltype="cf_sql_varchar">
                ,<cfqueryparam value="#REQUEST.SCookie.User.uname#" cfsqltype="CF_SQL_VARCHAR">
                ,#CreateODBCDateTime(Now())#
                ,<cfqueryparam value="#REQUEST.SCookie.User.uname#" cfsqltype="CF_SQL_VARCHAR">
                ,#CreateODBCDateTime(Now())#,
                <cfqueryparam value="#reviewee_empid#" cfsqltype="CF_SQL_VARCHAR">
                )
            </cfquery>
		<cfelse>
		
        <cfquery name="LOCAL.qUpdateEvalAttch" datasource="#request.sdsn#" result="LOCAL.vresult">
            UPDATE  TPMDPERF_EVALATTACHMENT 
            SET file_attachment = <cfqueryparam value="#file_name_save#" cfsqltype="cf_sql_varchar"> 
             WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
                AND period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND lib_type = <cfqueryparam value="#kpitype#" cfsqltype="cf_sql_varchar">
                AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
       
        </cfquery>
      
		</cfif>
		
        <cfoutput>
            <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSAttachment uploaded",true)>
            <cfset LOCAL.tempFileNameEncodedcs = URLEncodedFormat(file_name_save)>
            <script>
                alert('#SFLANG#');
                 
                var retContentAtt = `
                    <a target="_blank" href="?sfid=sys.util.getfile&amp;download=true&amp;code=evalattachment&amp;fname=#tempFileNameEncodedcs#">#HTMLEDITFORMAT(namefile)#</a>
        	        <img src="/sf6lib/images/icons/delete.png" class="delfilebtn" title="Delete File" alt="" onclick="deleteAttachmentEval#kpitype#('inp_fileupload_#idxattachment#','#idxattachment#','#file_name_save#')" style="cursor: pointer;" height="15px">`;
                
                parent.$("[id=upload_attach_#idxattachment#]").html(retContentAtt);
            </script>
        </cfoutput>

	</cffunction>

        
        	<cffunction name="Upload">

		    <cfparam name="del_prev" default="0">
			<cfparam name="detail" default="">
			<cfset LOCAL.qFailedData = QueryNew("ROW,COLUMN,REASON")>
			<cfset LOCAL.lstHeaderColumn = "EMPNO,EMP_NAME,PERIOD_CODE,FINAL_SCORE">
			<cfset LOCAL.nColumn = ListLen(lstHeaderColumn,",")> 
			<cfset LOCAL.tempRow = 0>
			<cfset errDetail = "">
			            <cfset LOCAL.SFLANGTEMPLATE=Application.SFParser.TransMLang("JSPlease Check Your Template KPI Library",true)>
			<cfif not isdefined("process")>
				<CF_SFUPLOAD ACTION="UPLOAD" CODE="planningupload" FILEFIELD="fileupload" onerror="parent.refreshPage();" output="xlsuploaded">
			
				<cfif xlsuploaded.ClientFileExt eq "xls">
				    <cfset  LOCAL.strFileExcel = xlsuploaded.SERVERDIRECTORY & "/" & xlsuploaded.SERVERFILE />
					<cfspreadsheet action="read" src="#strFileExcel#" columns = "1-#val(nColumn)#"  query="Local.qdata" headerrow="1" excludeHeaderRow="true" >
							<!---validasi header excel template--->
			<cfloop list="#lstHeaderColumn#" index="LOCAL.idxhead">
                <cfif NOT structKeyExists(qData, idxhead)>
                    <cfoutput>
                       
                	    <script>
                		    alert("#SFLANGTEMPLATE#");	
                            parent.maskButton(false);
                            parent.reloadPage();
                		</script>
                		<cf_sfabort>
                	</cfoutput>
                </cfif>
			</cfloop>
			<!---validasi header excel template--->
					<!--- TCK1018-81928 - Validasi Enterprise User --->
					<cfif qData.recordcount neq 0 >
                    	<cfset LOCAL.listSelectedParticipant = ValueList(qData.empno)>
                    	<cfset LOCAL.objEnterpriseUser= CreateObject("component", "SFEnterpriseUser") />
                    	<cfset LOCAL.retValidateEntSum=objEnterpriseUser.isEntExceedWithDefinedEmp(lstEmp_no=listSelectedParticipant)>
                        <cfif retValidateEntSum.retVal EQ false>
                            <cfset LOCAL.SFLANG=retValidateEntSum.message>
                    		<cfif REQUEST.SCOOKIE.MODE EQ "SFGO">
                                <cfset LOCAL.scValid={isvalid=false,result=""}>
                                <cfset scValid.result=SFLANG>
                                <cfreturn scValid/>
                    		<cfelse>
                        		<cfoutput>
                        			<script>
                        				alert("#SFLANG#");
            							parent.refreshPage();
        							</script>
                        		</cfoutput>
                        	</cfif>
        					<cf_sfabort/>
                    			<cfreturn false>
                        </cfif>
					</cfif>
						<!--- /TCK1018-81928 - Validasi Enterprise User --->
					<cfif ListLen(qdata.columnlist) neq ListLen(lstHeaderColumn)>
						<cfset LOCAL.SFLANG4=Application.SFParser.TransMLang("JSPlease check your file",true)>
						<cfoutput>
							<script>
								alert("#SFLANG4#");
								parent.refreshPage();	
							</script>
							<CF_SFABORT>
						</cfoutput>
					</cfif>
					<cfset LOCAL.TRANS_ID = "EVALUATION_UPLOAD#REQUEST.SCookie.User.empid##DateFormat(now(),'yyyymmdd')##TimeFormat(now(),'hhmmss')#">
					<cfif request.dbdriver eq "MYSQL">
						<cfquery name="LOCAL.qGetLastId" datasource="#REQUEST.SDSN#">
							SELECT MAX(id) AS maxid FROM TPMDWDDXTEMP
						</cfquery>
						
							 
							<cfif qGetLastId.maxid eq "">
								<cfset LOCAL.tempid = 1>
							<cfelse>
								<cfset LOCAL.tempid = val(qGetLastId.maxid)+1>
							</cfif>
					</cfif>
					<cfwddx action = "cfml2wddx" input = "#qData#" output = "LOCAL.query_wddx">
					<cfquery name="LOCAL.qInsPlanningWDDX" datasource="#REQUEST.SDSN#">
					<cfif request.dbdriver eq "MYSQL">
						INSERT INTO TPMDWDDXTEMP (id,trans_code,wddx,status,created_by,created_date,modified_by,modified_date,current_row,total) 
					    VALUES(<cfqueryparam value="#tempid#" cfsqltype="CF_SQL_INTEGER">
					    ,<cfqueryparam value="#TRANS_ID#" cfsqltype="CF_SQL_VARCHAR">
						,<cfqueryparam value="#query_wddx#" cfsqltype="CF_SQL_VARCHAR">
						,1
						,'#request.scookie.user.uname#'
						,#CreateODBCDateTime(Now())#
						,'#request.scookie.user.uname#'
						,#CreateODBCDateTime(Now())#
						,1
						,<cfqueryparam value="#qData.recordcount#" cfsqltype="cf_sql_integer">
						 )
					<cfelse>
						INSERT INTO TPMDWDDXTEMP (trans_code,wddx,status,created_by,created_date,modified_by,modified_date,current_row,total) 
						VALUES(
							<cfqueryparam value="#TRANS_ID#" cfsqltype="CF_SQL_VARCHAR">
							,<cfqueryparam value="#query_wddx#" cfsqltype="CF_SQL_VARCHAR">
							,1
							,'#request.scookie.user.uname#'
							,#CreateODBCDateTime(Now())#
							,'#request.scookie.user.uname#'
							,#CreateODBCDateTime(Now())#
							,1
							,<cfqueryparam value="#qData.recordcount#" cfsqltype="cf_sql_integer">
							)
					</cfif>
					</cfquery>
				    <cfif request.dbdriver eq "MYSQL">
						<cfset LOCAL.tempid = tempid + 1>
					</cfif>
					<cfoutput>
						<script>
							parent.showProgressBar(#qData.recordcount#,'#TRANS_ID#','#del_prev#');
						</script>
					</cfoutput>	
					<cfelse>
						<cfset LOCAL.SFLANG4=Application.SFParser.TransMLang("JSPlease upload xls format file",true)>
						<cfoutput>
							<script>
								alert("#SFLANG4#");
								maskButton(false);		
								parent.refreshPage();	
							</script>
							 <CF_SFABORT>
						</cfoutput>
					</cfif>
					<CF_SFUPLOAD ACTION="DELETE" CODE="planningupload" FILENAME="#xlsuploaded.SERVERFILE#" output="xlsuploadedDelete">
			    <cfelse>
					<cfset LOCAL.SkipProcess = false>
					<cfset LOCAL.tempRow = tempRow + 1>
					<cfset request.doctype="xml">
					<cfquery name="LOCAL.qTransCode" datasource="#REQUEST.SDSN#">
						SELECT max(trans_code) as trans_code FROM TPMDWDDXTEMP
						WHERE  trans_code = '#trans_id#'
					</cfquery>
					<cfquery name="LOCAL.qGetWddx" datasource="#REQUEST.SDSN#">
						SELECT wddx,current_row,total 
						FROM TPMDWDDXTEMP WHERE trans_code =<cfqueryparam value="#qTransCode.trans_code#" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>
					<cfwddx action = "wddx2cfml" input = "#qGetWddx.wddx#" output = "qData">
					<cfif qGetWddx.total lte 100 or qGetWddx.current_row eq 2>
						<cfset LOCAL.varMaxRows = 10>
					<cfelse>
						<cfset LOCAL.varMaxRows = 100>
					</cfif>
					<cfset LOCAL.CuPo = qGetWddx.current_row>
					
					<!---
					<cfif (CuPo gt 1) AND CuPo+1 GT qGetWddx.total>
					    <cfset LOCAL.SkipProcess = true>
					</cfif>
					--->
					
					<cfif (CuPo gt 1) and (CuPo+1 lte qGetWddx.total)>
						<cfset LOCAL.CuPo = CuPo+1>    
					</cfif>
					
					<cfset LOCAL.varEndPos = CuPo + varMaxRows - 1>
					<cfif varEndPos GT qData.recordcount>
					    <cfset LOCAL.varEndPos = qData.recordcount>
					</cfif>
					
					<cfset local.isReadytoExecute = true>
					<cfset LOCAL.tempRow = 0>
					<cfset LOCAL.empnotemp = "">
				    <cfloop query="qData"  startrow="#CuPo#" endrow="#varEndPos#">
				        <!---
				        <cfif SkipProcess EQ true> !---case redudant di terakhir---
                            <cfset LOCAL.detail = detail & "<DATA><ROWSEKARANG>#qData.currentrow#</ROWSEKARANG><DEL_PREV>#DEL_PREV#</DEL_PREV><NILAI>#qData.recordcount#</NILAI><HEADIDTEMP>#qTransCode.trans_code#</HEADIDTEMP></DATA>"> 
				            <cfcontinue>
			            </cfif>
			            --->
				        <cfquery name="LOCAL.qCheckPeriodCode" datasource="#REQUEST.SDSN#">
							SELECT period_code,score_type,conclusion_lookup,reference_date,use_verification from TPMMPERIOD where 
							period_code =  <cfqueryparam value="#qData.period_code#" cfsqltype="CF_SQL_VARCHAR"> 
						</cfquery>
						<cfquery name="qCheckScore" datasource="#REQUEST.SDSN#">
							SELECT a.score_code, b.score_desc, b.score_type, a.scoredet_mask,
							a.scoredet_value, a.scoredet_desc
							FROM TGEDSCOREDET a inner join TGEMSCORE b on a.score_code=b.score_code
							WHERE 
							<cfif qCheckPeriodCode.recordcount gt 0>
							    a.score_code = '#qCheckPeriodCode.conclusion_lookup#'
							    <cfelse>
						        1=0
							</cfif>
						
							ORDER BY a.scoredet_value desc
						</cfquery>
						<cfif empnotemp neq qData.empno>
							<cfset LOCAL.form_no = Application.SFUtil.getCode("PERFEVALFORM",'no','true')>  <!---for generate form no ---->
							<cfset LOCAL.req_no = Application.SFUtil.getCode("PERFORMANCEPLAN",'no','true','false','true')> <!---for generate request no ---->
					    </cfif>
						<cfset LOCAL.empnotemp = qData.empno>
						<cfset LOCAL.isReadytoExecute = true>
						<cfset LOCAL.tempRow = qData.currentrow>
						<cfset local.strctPlanH = StructNew()>
						<cfquery name="LOCAL.qUpdCurRow" datasource="#REQUEST.SDSN#">
							UPDATE TPMDWDDXTEMP set current_row= <cfqueryparam value="#qData.currentrow#" cfsqltype="CF_SQL_INTEGER"> 
							WHERE trans_code=<cfqueryparam value="#qTransCode.trans_code#" cfsqltype="CF_SQL_VARCHAR">
						</cfquery>
						<cfset LOCAL.idx="">
						<cfloop list="#lstHeaderColumn#" index="idx">
						    
							<cfset LOCAL.tempQData = Evaluate("qData.#idx#")>
							<cfif Trim(tempQData) eq "">
							    <cfif idx neq "EMP_NAME">
							        <cfset LOCAL.temp = QueryAddRow(qFailedData)>    
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Data #idx# is required")>
								    <cfset local.isReadytoExecute = false>
							    </cfif>
							<cfelseif Refind("<[^>]*>",tempQData) GT 0>
							        <cfset LOCAL.temp = QueryAddRow(qFailedData)>    
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
								    <cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Found html tag on colum #idx#")>
								    <cfset local.isReadytoExecute = false>
							<cfelse>
								<cfif UCASE(idx) eq "EMPNO">
									<cfquery name="qCheckEmp" datasource="#REQUEST.SDSN#">
										SELECT EMP_ID, position_id, grade_code, employ_code FROM TEODEMPCOMPANY WHERE EMP_NO =  <cfqueryparam value="#qData.empno#" cfsqltype="CF_SQL_VARCHAR"> 
										AND company_id =   <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
										AND status = 1
								    </cfquery>
									<cfif qCheckEmp.recordcount eq 0 >
										<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Employee No #qData.empno# is not registered in this company")>		
										<cfset local.isReadytoExecute = false>
									<cfelse>
										<!---<cfset local.isReadytoExecute = true>--->
								    </cfif>
								</cfif>
								<cfif UCASE(idx) eq "PERIOD_CODE">
								
									<cfif qCheckPeriodCode.recordcount eq 0 >
										<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Period Code #qData.period_code# is missing")>		
										<cfset local.isReadytoExecute = false>
									<cfelse>
									   
										<cfif qCheckScore.recordcount neq 0>
										    <cfset scoredet = valuelist(qCheckScore.scoredet_value)>
										</cfif>
								    </cfif>
								</cfif>
								<cfif UCASE(idx) eq "FINAL_SCORE">
									<cfif qData.final_score eq ''>
									    <cfset LOCAL.temp = QueryAddRow(qFailedData)>   
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
										<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
								        <cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Final Score is Empty")>		
										<cfset local.isReadytoExecute = false>
									<cfelse> 
									    <cfif qCheckScore.recordcount eq 0>
											<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
											<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
											<cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
											<cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Final Conclusion is not found")>		
											<cfset local.isReadytoExecute = false>
									   <cfelse>
											<cfset tempscore= qData.final_score>
											<cfset tempMask = ''>
											
										    <cfloop query='qCheckScore'>
											    <cfif qData.final_score lte qCheckScore.scoredet_value>
											        <cfset tempMask = qCheckScore.scoredet_mask>
												<cfelse>
													 <cfbreak>
												</cfif>
											</cfloop>  
											<cfif tempMask eq ''>
												<cfset LOCAL.temp = QueryAddRow(qFailedData)>   
												<cfset LOCAL.temp = QuerySetCell(qFailedData,"ROW","#qData.currentrow#")>
											    <cfset LOCAL.temp = QuerySetCell(qFailedData,"COLUMN","#idx#")>
											    <cfset LOCAL.temp = QuerySetCell(qFailedData,"REASON","Failed : Final Conclusion is not found")>			
											    <cfset local.isReadytoExecute = false>
											<cfelse>
												<!---<cfset local.isReadytoExecute = true>--->
											</cfif> 
											<!--- <cfset local.isReadytoExecute = true> --->
											<cfif isReadytoExecute eq true>
											   <cfset local.isReadytoExecute = true> 
                                                    <cfquery name="qCheckPerfFinal" datasource="#REQUEST.SDSN#">
													   select form_no , company_code from TPMDPERFORMANCE_FINAL where
													   period_code =  <cfqueryparam value="#qCheckPeriodCode.period_code#" cfsqltype="cf_sql_varchar">
													   and reviewee_empid =  <cfqueryparam value="#qCheckEmp.emp_id#" cfsqltype="cf_sql_varchar">
													</cfquery>
													<cfif qCheckPerfFinal.recordcount neq 0>
													   <cfquery name="Local.qUpdateFinalData" datasource="#request.sdsn#">
	    				                                   UPDATE TPMDPERFORMANCE_FINAL 
	    				                                   SET final_score = <cfqueryparam value="#qData.final_score#" cfsqltype="cf_sql_varchar">
	    				                                   ,final_conclusion = <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">
	    				                                   ,modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">
	    				                                   ,modified_date = <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>
	    				                                   ,ori_conclusion = <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">
	    				                                   <cfif qCheckPeriodCode.use_verification EQ 1 OR qCheckPeriodCode.use_verification EQ 'Y' >
	    				                                        ,on_verification = 1 <!---TCK2107-0658030--->
	    				                                    <cfelse>
	    				                                        ,on_verification = 0 <!---TCK2107-0658030--->
	    				                                    </cfif>
	    			                                        WHERE form_no = <cfqueryparam value="#qCheckPerfFinal.form_no#" cfsqltype="cf_sql_varchar">
	    	                                               AND company_code = <cfqueryparam value="#qCheckPerfFinal.company_code#" cfsqltype="cf_sql_varchar">
	    			                                    </cfquery>
												    <cfelse> 
													    <cfquery name="qInsertPerfFinal" datasource="#REQUEST.SDSN#">
													       INSERT INTO TPMDPERFORMANCE_FINAL (form_no,	company_code, period_code, reference_date, 
	                                                       reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, final_score, 
	                                                       final_conclusion, created_by, created_date, modified_by, modified_date,ori_score, ori_conclusion,is_upload, on_verification)
	                                                       values(
	                                                            <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qCheckPeriodCode.period_code#" cfsqltype="cf_sql_varchar">,     
	                                                            <cfqueryparam value="#qCheckPeriodCode.reference_date#" cfsqltype="cf_sql_timestamp">,
	                                                            <cfqueryparam value="#qCheckEmp.emp_id#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qCheckEmp.position_id#" cfsqltype="cf_sql_integer">,
	                                                            <cfqueryparam value="#qCheckEmp.grade_code#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qCheckEmp.employ_code#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#qData.final_score#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
	                                                            <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
	                                                            <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
	                                                            <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
	                                                            <cfqueryparam value="#qData.final_score#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="#tempMask#" cfsqltype="cf_sql_varchar">,
	                                                            <cfqueryparam value="Y" cfsqltype="cf_sql_varchar">,
	                                                            #qCheckPeriodCode.use_verification EQ 1 OR qCheckPeriodCode.use_verification EQ 'Y' ? '1' : '0'# <!---TCK2107-0658030--->
	                                                       )
	                                                   </cfquery>
	                                                                       
													</cfif>
													                   
											</cfif>
										</cfif>
								</cfif>
							</cfif>
						</cfif>
                    </cfloop>
                    <!--- <cfset LOCAL.detail = detail & "<DATA><ROWSEKARANG>#qData.currentrow#</ROWSEKARANG><DEL_PREV>#DEL_PREV#</DEL_PREV><NILAI>#qData.recordcount#</NILAI><HEADIDTEMP>#qTransCode.trans_code#</HEADIDTEMP></DATA>"> --->
                    <cfset LOCAL.detail = detail & "<DATA><ROWSEKARANG>#varEndPos#</ROWSEKARANG><DEL_PREV>#DEL_PREV#</DEL_PREV><NILAI>#qData.recordcount#</NILAI><HEADIDTEMP>#qTransCode.trans_code#</HEADIDTEMP></DATA>"> 

                </cfloop>                                
  			</cfif>		
  			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Performance Planning Upload",true)>
			<cfset LOCAL.SFLANG2=Application.SFParser.TransMLang("JSThis Employee already has Performance Evaluation Form",true)>
		    <cfset LOCAL.LstFailed = "">
            <cfif qFailedData.recordcount gt 0>
			   <cfloop query="qFailedData" >
					<cfset LOCAL.LstFailed =ListAppend(LstFailed,"#ROW#~#REASON#","|")>
					<cfset LOCAL.tempString = "<DATA><ERROR><ROW>#ROW#</ROW><REASON>#reason#</REASON></ERROR></DATA>">
					<cfif FindNoCase(tempString,detail) eq 0>
						<cfset LOCAL.detail = detail & tempString>
					</cfif>
			   </cfloop>
            </cfif>
                 
            <cfoutput>
                <cfxml variable="LOCAL.MyDoc"> 
                    <MyDoc>
                        #detail#
                    </MyDoc>
                </cfxml>                
                #MyDoc#        
            </cfoutput>
	</cffunction>
    
		<cffunction name="SaveTransaction">
	    	<cfargument name="iAction" type="numeric" required="yes">
	    	<cfargument name="strckFormData" type="struct" required="yes">
	    	<cfparam name="action" default="0">
	    	<cfparam name="sendtype" default="0">
	    	<cfset local.existInPlan = false>
			<cfset local.nhead_status = 0>
			
	        <cfif sendtype eq 'directfinal'>
	        	<cfset strckFormData.isfinal = 1/>
	        	<cfset strckFormData.head_status = 1/>
				<cfset nhead_status = 1>
	        <cfelseif action eq 'sendtoapprover' or sendtype eq 'next'>
	        	<cfset strckFormData.head_status = 1/>
				<cfset nhead_status = 1>
			<cfelseif action eq 'draft'>
				<cfset nhead_status = 1>
				<cfset strckFormData.head_status = 0/>
	        </cfif>
		
			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
				SELECT  grade_code, employ_code, position_id 
				FROM TEODEMPCOMPANY 
				WHERE emp_id = <cfqueryparam value="#strckFormData.requestfor#" cfsqltype="cf_sql_varchar">
				and status = 1
				AND company_id =  <cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_integer">
			</cfquery>
			<cfif qDetailReviewee.recordcount eq 0>
    			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
    				SELECT  grade_code, employ_code, position_id 
    				FROM TEODEMPCOMPANY 
    				WHERE emp_id = <cfqueryparam value="#strckFormData.requestfor#" cfsqltype="cf_sql_varchar">
    				and status = 1
    			</cfquery>
			</cfif>
			
			<cfquery name="local.qDetailReviewer" datasource="#request.sdsn#">
				SELECT  position_id 
				FROM TEODEMPCOMPANY 
				WHERE emp_id = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
				and status = 1
				AND company_id =  <cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_integer">
			</cfquery>
			<cfif qDetailReviewer.recordcount eq 0>
    			<cfquery name="local.qDetailReviewer" datasource="#request.sdsn#">
    				SELECT  position_id 
    				FROM TEODEMPCOMPANY 
    				WHERE emp_id = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
    			</cfquery>
			</cfif>
	        
	        <cfset LOCAL.listPeriodComponentUsed = ListRemoveDuplicates(listPeriodComponentUsed) >
			<cfif (listfindnocase(ucase(listPeriodComponentUsed),"ORGKPI") or listfindnocase(ucase(listPeriodComponentUsed),"PERSKPI")) and nhead_status eq 1>
	            <cfset local.retvar = cekOrgPersKPI(FORM.period_code,strckFormData.reference_date,strckFormData.requestfor,qDetailReviewee.position_id,FORM.coid,FORM.cocode)> 
	        </cfif>
			
	        <!--- cek if exist in plan --->
	        <cfif len(strckFormData["planformno"])>
	        	<cfset existInPlan = true>
			<cfelseif len(strckFormData["formno"])>
				<cfset existInPlan = true>
	        </cfif>
	        
	        <!--- insert tabel header --->
			<cfset local.strckHeadData = StructNew()>
	        <cfif len(strckFormData["formno"])>
				<cfset strckHeadData["form_no"] = strckFormData.formno>
	        <cfelseif len(strckFormData["planformno"])>
				<cfset strckHeadData["form_no"] = strckFormData.planformno>
	        <cfelse>
				<cfset strckHeadData["form_no"] = trim(Application.SFUtil.getCode("PERFEVALFORM",'no','true'))>
	        </cfif>
	        
	        <!---
	        <cfif not len(strckFormData["formno"])>
				<cfset strckHeadData["form_no"] = trim(Application.SFUtil.getCode("PERFEVALFORM",'no','true'))>
	        <cfelse>
				<cfset strckHeadData["form_no"] = strckFormData.formno>
	        </cfif>
			--->
			
			<cfset strckHeadData["request_no"] = request_no><!--- ? --->
			<cfset strckHeadData["form_order"] = 1>
			<cfset strckHeadData["reference_date"] = strckFormData.reference_date>
			<cfset strckHeadData["period_code"] = FORM.period_code>
			<cfset strckHeadData["company_code"] = FORM.cocode> <!---modified by  ENC51115-79853 --->
			<cfset strckHeadData["coid"] = FORM.coid> <!---added by  ENC51115-79853 --->
			<cfset strckHeadData["reviewee_empid"] = strckFormData.requestfor>
			<cfset strckHeadData["reviewee_posid"] = qDetailReviewee.position_id>
			<cfset strckHeadData["reviewee_grade"] = qDetailReviewee.grade_code>
			<cfset strckHeadData["reviewee_employcode"] = qDetailReviewee.employ_code>
			<cfset strckHeadData["reviewer_empid"] = request.scookie.user.empid>
			<cfset strckHeadData["reviewer_posid"] = qDetailReviewer.position_id>
			<cfset strckHeadData["score"] = strckFormData.score>
			<cfset strckHeadData["conclusion"] = strckFormData.conclusion>
	    	<cfset strckHeadData["review_step"] = strckFormData.UserInReviewStep/>
	        <cfif structkeyexists(strckFormData,"isfinal")>
		    	<cfset strckHeadData["isfinal"] = strckFormData.isfinal/>
	        <cfelse>
		    	<cfset strckHeadData["isfinal"] = 0/>
	        </cfif>
	        <cfif structkeyexists(strckFormData,"head_status")>
		    	<cfset strckHeadData["head_status"] = strckFormData.head_status/>
	        <cfelse>
		    	<cfset strckHeadData["head_status"] = 0/>
	        </cfif>
			<cfset strckHeadData["lastreviewer_empid"] = request.scookie.user.empid>
	        
	        <cfset local.listlibtype="0">
	        <cfloop list="#listPeriodComponentUsed#" index="local.idxComp">
	            <cfif ucase(idxComp) neq "TASK" and ucase(idxComp) neq "FEEDBACK" and ucase(idxComp) neq "questionComp" and ucase(idxComp) neq "additionaldeductComp">
	                <cfset local.listexist = evaluate("#idxComp#_lib")>
	                <cfif listlen(trim(listexist))>
	                    <cfset listlibtype = listAppend(listLibType,idxComp)>
	                </cfif>
	            </cfif>
	        </cfloop>
	        
	        <!---Set use_point for additional dan deduction--->
			<cfquery name="local.qDDelOldCOMP" datasource="#request.sdsn#">
				DELETE FROM TPMDEVALD_COMPPOINT 
				WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
				    AND request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
			</cfquery>
	        <cfif structkeyexists(strckFormData,"additionalpoint") OR structkeyexists(strckFormData,"deductpoint")>
		    	<cfset strckHeadData["use_point"] = 1/>
	        </cfif>
	        
	        <cfif structkeyexists(strckFormData,"jsonDetailDeductionValue") AND strckFormData['jsonDetailDeductionValue'] NEQ '' >
	            <cfset Local.tempJson = strckFormData['jsonDetailDeductionValue']>
	            <cfset Local.jsonDeduct = DeserializeJSON(tempJson)>
                <cfloop collection="#jsonDeduct#" item="Local.keyComp" >
    				<cfquery name="local.qInsertCOMP" datasource="#request.sdsn#">
    					INSERT INTO TPMDEVALD_COMPPOINT (form_no,request_no,comp_code,comp_type,total_comp,created_by,created_date,total_calcpoint) 
    					VALUES(
    						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#keyComp#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="D" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#val(jsonDeduct[keyComp])#" cfsqltype="cf_sql_integer">,
    						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
    						<cfqueryparam value="#strckFormData.deductpoint#" cfsqltype="cf_sql_varchar">
    					)				
    				</cfquery>
                </cfloop>
                
	        </cfif>
	        <cfif structkeyexists(strckFormData,"jsonDetailAdditionalValue") AND strckFormData['jsonDetailAdditionalValue'] NEQ ''>
	            <cfset Local.tempJson = strckFormData['jsonDetailAdditionalValue']>
	            <cfset Local.jsonDeduct = DeserializeJSON(tempJson)>
                <cfloop collection="#jsonDeduct#" item="Local.keyComp" >
    				<cfquery name="local.qInsertCOMP" datasource="#request.sdsn#">
    					INSERT INTO TPMDEVALD_COMPPOINT (form_no,request_no,comp_code,comp_type,total_comp,created_by,created_date,total_calcpoint) 
    					VALUES(
    						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#keyComp#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="A" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#val(jsonDeduct[keyComp])#" cfsqltype="cf_sql_integer">,
    						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
    						<cfqueryparam value="#strckFormData.additionalpoint#" cfsqltype="cf_sql_varchar">
    					)				
    				</cfquery>
                </cfloop>
	        </cfif>
	        
	        <cfif structkeyexists(strckFormData,"startDateCalcMethod") AND structkeyexists(strckFormData,"endDateCalcMethod")>
                <cfquery name="qGetdataSetting" datasource="#REQUEST.SDSN#" maxrows="1">
                    SELECT calc_method FROM TPMDCOMPPOINT 
                    WHERE period_code = <cfqueryparam value="#FORM.period_code#" cfsqltype="cf_sql_varchar">
                    ORDER BY comp_type DESC
                </cfquery>
                <cfif qGetdataSetting.calc_method EQ 'E' >
                    <cfif strckFormData.startDateCalcMethod NEQ '' AND strckFormData.endDateCalcMethod NEQ ''>
        				<cfquery name="local.qUpdateComp" datasource="#request.sdsn#">
        					UPDATE TPMDEVALD_COMPPOINT 
        					SET start_date = <cfqueryparam value="#strckFormData.startDateCalcMethod#" cfsqltype="cf_sql_date"/>,
        					    end_date = <cfqueryparam value="#strckFormData.endDateCalcMethod#" cfsqltype="cf_sql_date"/>
        					WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
        					    AND request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
        				</cfquery>
    				</cfif>
    			<cfelse>
    				<cfquery name="local.qUpdateComp" datasource="#request.sdsn#">
    					UPDATE TPMDEVALD_COMPPOINT 
    					SET start_date = NULL,
    					    end_date = NULL
    					WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
    					    AND request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
    				</cfquery>
                </cfif>
	        </cfif>
	        
	        <!---
	        <cfif structkeyexists(strckFormData,"lstValCompCodeAdditional")>
		    	<cfloop list="#strckFormData['lstValCompCodeAdditional']#" index="local.idxcomcode">
    				<cfquery name="local.qInsertCOMP" datasource="#request.sdsn#">
    					INSERT INTO TPMDEVALD_COMPPOINT (form_no,request_no,comp_code,comp_type) 
    					VALUES(
    						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#idxcomcode#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="A" cfsqltype="cf_sql_varchar">
    					)				
    				</cfquery>
		    	</cfloop>
	        </cfif>
	        <cfif structkeyexists(strckFormData,"lstValCompCodeDeduction")>
		    	<cfloop list="#strckFormData['lstValCompCodeDeduction']#" index="local.idxcomcode">
    				<cfquery name="local.qInsertCOMP" datasource="#request.sdsn#">
    					INSERT INTO TPMDEVALD_COMPPOINT (form_no,request_no,comp_code,comp_type) 
    					VALUES(
    						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="#idxcomcode#" cfsqltype="cf_sql_varchar">,
    						<cfqueryparam value="D" cfsqltype="cf_sql_varchar">
    					)				
    				</cfquery>
		    	</cfloop>
	        </cfif>
	        --->
	        <!---Set use_point for additional dan deduction--->
			
	        <cftransaction>
			
	      	<cfquery name="local.qDelDataBefore" datasource="#request.sdsn#">
	           	DELETE FROM TPMDPERFORMANCE_EVALNOTE
	            WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
	                 AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
					 AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar">  <!----added by  ENC51115-79853 --->
	        </cfquery>
	        <cfquery name="local.qDelDataBefore" datasource="#request.sdsn#">
	           	DELETE FROM TPMDPERFORMANCE_EVALD
	            WHERE form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
	                AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar">  <!----added by  ENC51115-79853 --->
	                AND (lib_type in (#ListQualify(listlibtype,"'",",","ALL")#)
					<cfif listPeriodComponentUsed neq "">
						 OR(lib_code in (#ListQualify(listPeriodComponentUsed,"'",",","ALL")#) and lib_type = 'COMPONENT')
					</cfif>
					)
	               
	        </cfquery>
	        <cfquery name="local.qDelDataBefore" datasource="#request.sdsn#">
	           	DELETE FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
	            	AND form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar">  <!----added by  ENC51115-79853 --->
	                AND reviewee_empid = <cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">
	                AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	                AND period_code = <cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">
	        </cfquery>
			<!---<cfquery name="qInsEvalH" datasource="#request.sdsn#">
	           	INSERT INTO TPMDPERFORMANCE_EVALH (form_no, request_no, form_order, reference_date, period_code, company_code, reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, reviewer_empid, reviewer_posid, score, conclusion, isfinal, review_step, head_status, lastreviewer_empid, created_by, created_date, modified_by, modified_date)
				VALUES ( <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.form_order#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.reference_date#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewee_posid#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.reviewee_grade#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewee_employcode#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_posid#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.score#" cfsqltype="cf_sql_float">,
						<cfqueryparam value="#strckHeadData.conclusion#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.isfinal#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.review_step#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.head_status#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#strckHeadData.lastreviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
				)
	        </cfquery>--->
			 <cfset local.retvar = variables.objPerfEvalH.Insert(strckHeadData)>
	       <!--- panggil fungsi untuk period component --->
	        <cfset Local.stringJSON = "">
			
	        <cfloop list="#listPeriodComponentUsed#" index="local.idxCompUsed">
	        	<cfif listfindnocase("APPRAISAL,ORGKPI,PERSKPI,COMPETENCY",ucase(idxCompUsed))>
			        <cfset local.listLib = "">
			        <cfif structkeyexists(FORM,"#idxCompUsed#_lib")>
				        <cfset local.listLib = FORM["#idxCompUsed#_lib"]>
			        </cfif>
	            	<cfif structkeyexists(FORM,"#idxCompUsed#Array")>
	                	<cfset stringJSON = FORM["#idxCompUsed#Array"]>
	                </cfif>
					
	                <cfif listlen(listLib)>
						
				       	<cfset saveEvalD(idxCompUsed,listlib,strckHeadData,stringJSON,existInPlan)>
	                </cfif>
	            </cfif>
	            
	            <!--- insert per komponen period yang dipakai --->
	            <cfset local.strckEvalD = structnew()>
		        <cfset strckEvalD["form_no"] = strckHeadData.form_no>
		        <cfset strckEvalD["company_code"] = FORM.cocode> <!----added by  ENC51115-79853 --->
				<cfset strckEvalD["coid"] = FORM.coid> <!----added by  ENC51115-79853 --->
		        <cfset strckEvalD["reviewer_empid"] = strckHeadData.reviewer_empid>
		        <cfset strckEvalD["reviewer_posid"] = strckHeadData.reviewer_posid>
		        <cfset strckEvalD["lib_type"] = "COMPONENT">
				<cfset strckEvalD["lib_code"] = ucase(idxCompUsed)>
				<!---<cfif ucase(idxCompUsed) neq "questionComp" AND ucase(idxCompUsed) neq "additionaldeductComp">--->
				<cfif ucase(idxCompUsed) neq "additionaldeductComp">
    	            <cfif ucase(idxCompUsed) eq "ORGKPI">
    			        <cfset strckEvalD["weight"] = strckFormData["objectiveorg_weight"]>
    			        <cfset strckEvalD["score"] = strckFormData["objectiveorg"]>
    			        <cfset strckEvalD["weightedscore"] = strckFormData["objectiveorg_weighted"]>
    	            <cfelseif ucase(idxCompUsed) eq "PERSKPI">
    			        <cfset strckEvalD["weight"] = strckFormData["objective_weight"]>
    			        <cfset strckEvalD["score"] = strckFormData["objective"]>
    			        <cfset strckEvalD["weightedscore"] = strckFormData["objective_weighted"]>
    	            <cfelse>
    			        <cfset strckEvalD["weight"] = strckFormData["#lcase(idxCompUsed)#_weight"]>
    			        <cfset strckEvalD["score"] = strckFormData["#lcase(idxCompUsed)#"]>
    			        <cfset strckEvalD["weightedscore"] = strckFormData["#lcase(idxCompUsed)#_weighted"]>
    	            </cfif>
    	            <cfset retvar = variables.objPerfEvalD.Insert(strckEvalD)> 
				
	            </cfif>
				
				<!---- <cfquery name="local.qInsertEvalD" datasource="#request.sdsn#">
					INSERT INTO TPMDPERFORMANCE_EVALD (form_no,reviewer_empid,reviewer_posid,lib_code,lib_type,company_code,weight,score,
	weightedscore,created_by,created_date,modified_by,modified_date) 
					VALUES(
						<cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_posid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weight#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.score#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weightedscore#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					)				
				</cfquery> -----> <!--- remarked by maghdalenasp 2018-03-21 ---->
	            
	        </cfloop>
	        
			<!--- insert additional notes --->
	        <cfif structkeyexists(StrckFormData,"evalnoterecords")>
			<cfloop from="1" to="#StrckFormData.evalnoterecords#" index="local.idx">
				<cfset local.note_name = strckFormData["evalnotename_#idx#"]>
				<cfset local.note_answer = strckFormData["evalnote_#idx#"]>
				<cfquery name="local.qInsertAddNotes" datasource="#request.sdsn#">
					INSERT INTO TPMDPERFORMANCE_EVALNOTE (form_no,company_code,reviewer_empid,reviewer_posid,note_name,note_answer,note_order,created_by,created_date,modified_by,modified_date) 
					VALUES(
						<cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckHeadData.reviewer_posid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#note_name#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#note_answer#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#idx#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					)				
				</cfquery>
			</cfloop>
	        </cfif>
	        
	        <!--- Insert ke Tabel Final --->
	        <cfif strckHeadData.isfinal eq 1>
		        <cfquery name="local.qCheckIfExistsInFinal" datasource="#request.sdsn#">
		             SELECT  EH.form_no,EH.company_code,EH.score,EH.conclusion FROM TPMDPERFORMANCE_FINAL F
		            LEFT JOIN TPMDPERFORMANCE_EVALH EH ON F.form_no = EH.form_no AND F.company_code = EH.company_code
		            WHERE EH.request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar"> AND EH.isfinal = 1
		        </cfquery>
		        
        
		        <cfquery name="LOCAL.qCheckPeriodCode" datasource="#REQUEST.SDSN#">
					SELECT period_code,score_type,conclusion_lookup,reference_date,use_verification from TPMMPERIOD where 
					period_code =  <cfqueryparam value="#strckHeadData.period_code#" cfsqltype="CF_SQL_VARCHAR"> 
				</cfquery>
		        
		        <cfif not qCheckIfExistsInFinal.recordcount>
	    	        <cfquery name="Local.DelFinal" datasource="#request.sdsn#">
	    	            DELETE FROM TPMDPERFORMANCE_FINAL
	    	            WHERE form_no = <cfqueryparam value="#qCheckIfExistsInFinal.form_no#" cfsqltype="cf_sql_varchar">
	    	                AND company_code = <cfqueryparam value="#qCheckIfExistsInFinal.company_code#" cfsqltype="cf_sql_varchar">
	    			</cfquery>
	    	        <cfquery name="Local.qInsertFinalData" datasource="#request.sdsn#">
	    				INSERT INTO TPMDPERFORMANCE_FINAL (form_no,	company_code, period_code, reference_date, reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, final_score, final_conclusion, created_by, created_date, modified_by, modified_date,ori_score, ori_conclusion, on_verification)
	        	        SELECT EH.form_no, EH.company_code, EH.period_code, EH.reference_date, EH.reviewee_empid, EH.reviewee_posid, EH.reviewee_grade, EH.reviewee_employcode, EH.score AS final_score, EH.conclusion AS final_conclusion, '#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>, '#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,EH.score AS ori_score, EH.conclusion AS ori_conclusion
	        	        ,#qCheckPeriodCode.use_verification EQ 1 OR qCheckPeriodCode.use_verification EQ 'Y' ? '1' : '0'# as on_verification
	    	            FROM TPMDPERFORMANCE_EVALH EH
	    			    WHERE request_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
	    	                AND isfinal = 1
	    			</cfquery>
	            <!---BUG50915-51098--->
	            <cfelse>
	                <cfquery name="Local.qUpdateFinalData" datasource="#request.sdsn#">
	    				UPDATE TPMDPERFORMANCE_FINAL 
	    				SET final_score = <cfqueryparam value="#qCheckIfExistsInFinal.score#" cfsqltype="cf_sql_varchar">
	    				,final_conclusion = <cfqueryparam value="#qCheckIfExistsInFinal.conclusion#" cfsqltype="cf_sql_varchar">
	    				,modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">
	    				,modified_date = <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>
	    				,ori_conclusion = <cfqueryparam value="#qCheckIfExistsInFinal.conclusion#" cfsqltype="cf_sql_varchar">
	    				
        		        <cfif qCheckPeriodCode.use_verification EQ 1 OR qCheckPeriodCode.use_verification EQ 'Y' >
                            ,on_verification = 1 <!---TCK2107-0658030--->
                        <cfelse>
                            ,on_verification = 0 <!---TCK2107-0658030--->
                        </cfif>
	    				
	    			    WHERE form_no = <cfqueryparam value="#qCheckIfExistsInFinal.form_no#" cfsqltype="cf_sql_varchar">
	    	            AND company_code = <cfqueryparam value="#qCheckIfExistsInFinal.company_code#" cfsqltype="cf_sql_varchar">
	    			</cfquery>
	            </cfif>
	            <!---BUG50915-51098--->
	        </cfif>

	        <!--- Approved Data Request --->
	        <cfif strckHeadData.head_status eq 1 and (strckFormData.RevieweeAsApprover neq 1 or (strckFormData.RevieweeAsApprover eq 1 and strckFormData.requestfor neq request.scookie.user.empid))>
	            <cfquery name="local.qGetApprovedDataFromReq" datasource="#request.sdsn#">
	            	SELECT  approved_data FROM TCLTREQUEST
					WHERE req_type = 'PERFORMANCE.EVALUATION'
						AND req_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
						AND company_id = <cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_integer"> <!----added by  ENC51115-79853 --->
						AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!----added by  ENC51115-79853 --->
						
	            </cfquery>

	            <cfset LOCAL.strckApprovedData=SFReqFormat(qGetApprovedDataFromReq.approved_data,"R")>
	            <!---TW:<cfif IsJSON(qGetApprovedDataFromReq.approved_data)>
	                <cfset LOCAL.strckApprovedData=DeserializeJSON(qGetApprovedDataFromReq.approved_data)>
				<cfelseif IsWDDX(qGetApprovedDataFromReq.approved_data)>
					<cfwddx action="wddx2cfml" input="#qGetApprovedDataFromReq.approved_data#" output="LOCAL.strckApprovedData">
	            <cfelse>
					<cfset LOCAL.strckApprovedData = StructNew() />
	            </cfif>--->
				<cfset var strckFormInbox = StructNew() />
				<cfset strckFormInbox['DTIME'] = Now() />
				<cfset strckFormInbox['DECISION'] = 1 />
				<cfset strckFormInbox['NOTES'] = "" />
				<cfset LOCAL.apvdDataKey = request.scookie.user.uid >
				<cfif trim(qGetApprovedDataFromReq.approved_data) eq '' OR (isStruct(strckApprovedData) AND REFind('_', ListFirst(StructKeyList(strckApprovedData)) ) ) >
					<cfset LOCAL.cntStrckApprovedData = StructCount(strckApprovedData)+1 />
					<cfset apvdDataKey = NumberFormat(cntStrckApprovedData,'00')&'_'&apvdDataKey >
				</cfif>
				<cfset strckApprovedData[apvdDataKey] = strckFormInbox />
				<cfset LOCAL.wddxApprovedData=SFReqFormat(strckApprovedData,"W")>
				<!---TW:<cfwddx action="cfml2wddx" input="#strckApprovedData#" output="wddxApprovedData">--->
				
				
	   	       	<cfquery name="local.qUpdApprovedData" datasource="#request.sdsn#">
					UPDATE TCLTREQUEST
					SET approved_data = <cfqueryparam value="#wddxApprovedData#" cfsqltype="cf_sql_varchar">
					WHERE req_type = 'PERFORMANCE.EVALUATION'
						AND req_no = <cfqueryparam value="#strckHeadData.request_no#" cfsqltype="cf_sql_varchar">
						AND company_id = <cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_integer"> <!----added by  ENC51115-79853 --->
						AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!----added by  ENC51115-79853 --->
				
				</cfquery>
	        </cfif>
	          	<cfquery name="local.qcheckEvalAttach" datasource="#request.sdsn#">
				  
                SELECT form_no,file_attachment
                FROM TPMDPERF_EVALATTACHMENT 
                WHERE period_code = <cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
          
                AND reviewer_empid = <cfqueryparam value="#strckHeadData.reviewer_empid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">
            </cfquery>
          
                	<cfquery name="local.updateformno" datasource="#request.sdsn#" result="qupdate" >
                	    update TPMDPERF_EVALATTACHMENT set form_no = <cfqueryparam value="#strckHeadData.form_no#" cfsqltype="cf_sql_varchar">
                	     WHERE period_code = <cfqueryparam value="#strckHeadData.period_code#" cfsqltype="cf_sql_varchar">
                AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
                AND reviewee_empid = <cfqueryparam value="#strckHeadData.reviewee_empid#" cfsqltype="cf_sql_varchar">
                	</cfquery>
                
	        </cftransaction>
	    </cffunction>
	    
	    
	    <cffunction name="saveEvalD">
	    	<cfargument name="libtype" default="">
	    	<cfargument name="listlib" default="">
	        <cfargument name="strckEval" default="">
	        <cfargument name="strJSON" default="">
	        <cfargument name="existInPlan" default="false">
	        <cfset local.strckEvalD = structnew()>
	        <cfset strckEvalD["form_no"] = strckEval.form_no>
	        <cfset strckEvalD["company_code"] = strckEval.company_code>
			<cfset strckEvalD["coid"] = strckEval.coid>
	        <cfset strckEvalD["reviewer_empid"] = strckEval.reviewer_empid>
	        <cfset strckEvalD["reviewer_posid"] = strckEval.reviewer_posid>
	        <cfset strckEvalD["lib_type"] = ucase(arguments.libtype)>
			<!--- anomali --->
			<cfif len(arguments.strJSON) and left(arguments.strJSON,1) eq " ">
	        	<cfset strJSON = Replace(strJSON, " ", "" ,"one")>
	        </cfif>
			<cfset local.objJSON = deserializeJSON(strJSON)>
	        <cfif len(arguments.listlib) and left(arguments.listlib,1) eq " ">
	        	<cfset listlib = Replace(listlib, " ", "" ,"one")>
	        </cfif>
	    
	        <cfset local.inputPrefix = "">
	        <cfif ucase(libtype) eq "APPRAISAL">
	        	<cfset inputPrefix = "appr">
	        <cfelseif ucase(libtype) eq "ORGKPI">
	        	<cfset inputPrefix = "org">
	        <cfelseif ucase(libtype) eq "PERSKPI">
	        	<cfset inputPrefix = "pers">
	        <cfelseif ucase(libtype) eq "COMPETENCY">
	        	<cfset inputPrefix = "comp">
	        </cfif>
			
			<cfquery name="local.qFromPlan" datasource="#request.sdsn#">
				SELECT  reviewer_empid,request_no FROM TPMDPERFORMANCE_PLANH
				WHERE form_no = <cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
					AND reviewee_empid = <cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">
					AND isfinal = 1
			</cfquery>
			 
	        <!--- ambil library details baik dari plan jika ada/ dari period lib langsung --->
	        <cfif UCASE(libtype) eq "PERSKPI">
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT * FROM TPMDPERFORMANCE_PLAND
	                WHERE form_no = <cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">
	                    AND company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
	                    AND UPPER(lib_type) = 'PERSKPI'
						AND reviewer_empid = <cfqueryparam value="#qFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
						AND request_no = <cfqueryparam value="#qFromPlan.request_no#" cfsqltype="cf_sql_varchar">
	            </cfquery>
				
	        <cfelseif UCASE(libtype) eq "ORGKPI">
	            <cfquery name="local.qGetOrgUnit" datasource="#request.sdsn#">
	                SELECT DISTINCT dept_id FROM TEOMPOSITION
	                WHERE position_id = <cfqueryparam value="#strckEval.reviewee_posid#" cfsqltype="cf_sql_integer">
	                    AND company_id = <cfqueryparam value="#strckEval.coid#" cfsqltype="cf_sql_integer">
	            </cfquery>
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT * FROM TPMDPERFORMANCE_PLANKPI
	                WHERE orgunit_id = <cfqueryparam value="#qGetOrgUnit.dept_id#" cfsqltype="cf_sql_integer">
	                    AND company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#strckEval.period_code#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	       
	        <cfelseif libtype eq "APPRAISAL">
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT appraisal_name_en AS lib_name_en,
	                    appraisal_name_id AS lib_name_id,
	                    appraisal_name_my AS lib_name_my,
	                    appraisal_name_th AS lib_name_th,
	                    appraisal_desc_en AS lib_desc_en,
	                    appraisal_desc_id AS lib_desc_id,
	                    appraisal_desc_my AS lib_desc_my,
	                    appraisal_desc_th AS lib_desc_th,
	                    apprlib_code AS lib_code,
	                    iscategory,
	                    appraisal_depth AS lib_depth,
	                    parent_code,
	                    parent_path
	                FROM TPMDPERIODAPPRLIB
	                WHERE company_code = <cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#strckEval.period_code#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	        <cfelseif libtype eq "COMPETENCY">
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT competence_name_en AS lib_name_en,
	                    competence_name_id AS lib_name_id,
	                    competence_name_my AS lib_name_my,
	                    competence_name_th AS lib_name_th,
	                    competence_desc_en AS lib_desc_en,
	                    competence_desc_id AS lib_desc_id,
	                    competence_desc_my AS lib_desc_my,
	                    competence_desc_th AS lib_desc_th,
	                    competence_code AS lib_code,
	                    iscategory,
	                    competence_depth AS lib_depth,
	                    parent_code,
	                    parent_path
	                FROM TPMMCOMPETENCE
	            </cfquery>
	        </cfif>
		
			
	        <cfloop list="#arguments.listlib#" index="local.idxLib">
	            <cfif idxLib eq "questionComp" or  idxLib eq "QUESTIONCOMP" or  idxLib eq "additionaldeductComp">
	                <cfbreak>
	            </cfif>
	            <cfquery name="local.qGetLibDetail" dbtype="query">
	                SELECT *
	                FROM qGetLibraryDetails
	                WHERE lib_code = <cfqueryparam value="#idxLib#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            
				<cfset strckEvalD["lib_code"] = idxLib>

	            <cfif UCASE(qGetLibDetail.iscategory) eq "N" OR qGetLibDetail.iscategory eq "" >
					<cfif structkeyexists(objJSON,"#inputPrefix#_weight_#idxLib#")>
						<cfset strckEvalD["weight"]  = objJSON["#inputPrefix#_weight_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["weight"]  = 0>
					</cfif>
					<cfif structkeyexists(objJSON,"#inputPrefix#_achievement_#idxLib#")>
						<cfset strckEvalD["achievement"]  = objJSON["#inputPrefix#_achievement_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["achievement"]  = 0>
					</cfif>
					<cfif structkeyexists(objJSON,"#inputPrefix#_score_#idxLib#")>
						<cfset strckEvalD["score"] = objJSON["#inputPrefix#_score_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["score"] = 0>
					</cfif>
	    	       
	                
					<cfif structkeyexists(objJSON,"#inputPrefix#_weightedscore_#idxLib#")>
						<cfset strckEvalD["weightedscore"] = objJSON["#inputPrefix#_weightedscore_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["weightedscore"] = 0>
					</cfif>
	    	       <cfif structkeyexists(objJSON,"#inputPrefix#_target_#idxLib#")>
						<cfset strckEvalD["target"] = objJSON["#inputPrefix#_target_#idxLib#"]>
					<cfelse>
						<cfset strckEvalD["target"] = 0>
					</cfif>
	    	      
					<cfif structkeyexists(objJSON,"#inputPrefix#_note_#idxLib#")>
						 <cfset strckEvalD["notes"] = objJSON["#inputPrefix#_note_#idxLib#"]>
					<cfelse>
						 <cfset strckEvalD["notes"] = "">
					</cfif>
	                <cfif listfindnocase("APPRAISAL,ORGKPI,PERSKPI",libtype)>
						<cfif structkeyexists(objJSON,"#inputPrefix#_achtype_#idxLib#")>
							 <cfset strckEvalD["achievement_type"] = objJSON["#inputPrefix#_achtype_#idxLib#"]>
						<cfelse>
							 <cfset strckEvalD["achievement_type"] = "">
						</cfif>
						<cfif structkeyexists(objJSON,"#inputPrefix#_looktype_#idxLib#")>
							 <cfset strckEvalD["lookup_code"] = objJSON["#inputPrefix#_looktype_#idxLib#"]>
						<cfelse>
							 <cfset strckEvalD["lookup_code"] = "">
						</cfif>
	    	        </cfif>
				<cfelse>
					<cfset strckEvalD["weight"] = "">
	    	        <cfset strckEvalD["achievement"] = "">
	    	        <cfset strckEvalD["score"] = "">
	    	        <cfset strckEvalD["weightedscore"] = 0>
	    	        <cfset strckEvalD["target"] = "">
					<cfset strckEvalD["notes"] = "">
	                <cfif listfindnocase("APPRAISAL,ORGKPI,PERSKPI",libtype)>
						<cfset strckEvalD["achievement_type"] = "">
						<cfset strckEvalD["lookup_code"] = "">
					</cfif>
	            </cfif>
	                
		        <cfset strckEvalD["lib_name_en"] = qGetLibDetail.lib_name_en>
		        <cfset strckEvalD["lib_name_id"] = qGetLibDetail.lib_name_id>
		        <cfset strckEvalD["lib_name_my"] = qGetLibDetail.lib_name_my>
		        <cfset strckEvalD["lib_name_th"] = qGetLibDetail.lib_name_th>
		        <cfset strckEvalD["lib_desc_en"] = qGetLibDetail.lib_desc_en>
		        <cfset strckEvalD["lib_desc_id"] = qGetLibDetail.lib_desc_id>
		        <cfset strckEvalD["lib_desc_my"] = qGetLibDetail.lib_desc_my>
		        <cfset strckEvalD["lib_desc_th"] = qGetLibDetail.lib_desc_th>
		        <cfset strckEvalD["iscategory"] = qGetLibDetail.iscategory>
		        <cfset strckEvalD["lib_depth"] = qGetLibDetail.lib_depth>
		        <cfset strckEvalD["parent_code"] = qGetLibDetail.parent_code>
		        <cfset strckEvalD["parent_path"] = qGetLibDetail.parent_path>
				<cfset local.retvar = variables.objPerfEvalD.Insert(strckEvalD)>   
				<!----<cfquery name="local.qInsertEvalD" datasource="#request.sdsn#">
					INSERT INTO TPMDPERFORMANCE_EVALD (form_no,reviewer_empid,reviewer_posid,lib_code,lib_type,company_code,weight,achievement,score,weightedscore,target,notes,created_by,created_date,modified_by,modified_date,lib_name_en,lib_desc_en,iscategory,lib_depth,parent_code,parent_path,achievement_type,lookup_code) 
					VALUES (
						<cfqueryparam value="#strckEvalD.form_no#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_empid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.reviewer_posid#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.company_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weight#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.achievement#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.score#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.weightedscore#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.target#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.notes#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						#now()#,
						<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
						#now()#,
						<cfqueryparam value="#strckEvalD.lib_name_en#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_desc_en#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.iscategory#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lib_depth#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.parent_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.parent_path#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.achievement_type#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#strckEvalD.lookup_code#" cfsqltype="cf_sql_varchar">
						
						
					)				
				</cfquery> remarked by maghdalenasp 2018-03-21 ------->

	            <!--- input ke TEOREMPCOMPETENCE--->
	            <cfif ucase(libtype) eq "COMPETENCY">
	            	<cfif len(strckEvalD.achievement)>
	            	
	            	    <!---Add data to history Log--->
	                    <cfquery name="LOCAL.qCekTableLog"  datasource="#request.sdsn#">
                            SELECT DISTINCT table_name from information_schema.tables
                			where upper(table_name) = 'TEODEMPCOMPETENCELOG' 
	                    </cfquery>
	                    <cfif qCekTableLog.recordcount neq 0>
    	            	    
                            <cfquery name="Local.qGetCurrentDataCompt" datasource="#request.sdsn#">
        	                	SELECT point_value FROM TEOREMPCOMPETENCE
        	                    WHERE emp_id = <cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">
        	                    	AND competence_code = <cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">
        	                </cfquery>
        	                <cfif qGetCurrentDataCompt.recordcount NEQ 0 >
        	                    <cfquery name="Local.qInsertEmpCompt" datasource="#request.sdsn#">
                	                	INSERT INTO TEODEMPCOMPETENCELOG 
                						( 
                						    emp_id,competence_code, ori_point, current_point, created_by, created_date, modified_by, modified_date, remark 
                						)
                						VALUES 
                						(
                    						<cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">,
                    						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
                    						<cfqueryparam value="#qGetCurrentDataCompt.point_value#" cfsqltype="cf_sql_varchar">,
                    						<cfqueryparam value="#strckEvalD.achievement#" cfsqltype="cf_sql_integer">,
                    						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
                    						<cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
                    						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
                    						<cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
                    						'PERFORMANCE EVALUATION'
                						)
            	                </cfquery>
        	                </cfif>
    	                </cfif>
	            	    <!---Add data to history Log--->
	            	
	            	
    	            	<cfquery name="Local.qDelEmpCompt" datasource="#request.sdsn#">
    	                	DELETE FROM TEOREMPCOMPETENCE
    	                    WHERE emp_id = <cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">
    	                    	AND competence_code = <cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">
    	                </cfquery>
    	                <cfquery name="qCheckCompetencyPOINT" datasource="#REQUEST.SDSN#">
    						SELECT point_value from TPMDCOMPETENCEPOINT where competence_code  = <cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="CF_SQL_VARCHAR"> and point_value = <cfqueryparam value="#strckEvalD.achievement#" cfsqltype="cf_sql_integer">
    					</cfquery>
    					<cfif qCheckCompetencyPOINT.recordcount gt 0>
        	            	<cfquery name="Local.qInsertEmpCompt" datasource="#request.sdsn#">
        	                	INSERT INTO TEOREMPCOMPETENCE
        						(emp_id, competence_code, point_value, created_by, created_date, modified_by, modified_date)
        						VALUES 
        						(
        						<cfqueryparam value="#strckEval.reviewee_empid#" cfsqltype="cf_sql_varchar">,
        						<cfqueryparam value="#strckEvalD.lib_code#" cfsqltype="cf_sql_varchar">,
        						<cfqueryparam value="#strckEvalD.achievement#" cfsqltype="cf_sql_integer">,
        						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
        						<cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
        						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
        						<cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>
        						)
        	                </cfquery>
    	                </cfif>
	                </cfif>
	            </cfif>
	        </cfloop>
	    </cffunction>
	    
	    <cffunction name="Revise">
	        <cfset local.reqno = FORM.request_no/>
	        <cfset local.formno = FORM.formno/>
	        <cfset local.requestfor = FORM.requestfor/>
	        <cfset local.periodcode = FORM.period_code/>
	        <cfset local.refdate = FORM.reference_date/>

	        <cftransaction>
	        <cfquery name="local.qCheckRequest" datasource="#request.sdsn#">
	        	SELECT approval_data, approval_list, approved_list, outstanding_list, approved_data FROM TCLTREQUEST
	            WHERE company_id =<cfqueryparam value="#FORM.coid#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	            AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	            AND req_type = 'PERFORMANCE.EVALUATION'
	            AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reqemp = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
				
	        </cfquery>
	        
            <cfset LOCAL.strckData = FORM/>
            
        	<cfquery name="local.qSelStepHigher" datasource="#request.sdsn#">
            	SELECT reviewer_empid FROM TPMDPERFORMANCE_EVALH 
            	WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
            	AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
            	AND review_step > <cfqueryparam value="#strckData.USERINREVIEWSTEP#" cfsqltype="cf_sql_varchar">
            	AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfloop query="qSelStepHigher">
        	    <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
            	    DELETE FROM  TPMDPERFORMANCE_EVALD 
            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
            	    AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                </cfquery>
                
                <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
            	    DELETE FROM  TPMDPERFORMANCE_EVALH 
            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
            		AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
            	    AND company_code = <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                </cfquery>
            </cfloop>
          
	        <cfquery name="local.qGetSPMH" datasource="#request.sdsn#">
	        	SELECT reviewer_empid, review_step, request_no FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	            AND company_code = <cfqueryparam value="#FORM.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	            AND head_status = 1
	            ORDER BY review_step ASC
	        </cfquery>
	        
	        <cfset local.new_outstanding =  qCheckRequest.outstanding_list/>
	        <cfset local.new_approved =  qCheckRequest.approved_list/>

			<cfset LOCAL.arr_approvaldata=SFReqFormat(qCheckRequest.approval_data,"R",[])>
			<!---TW:<cfwddx action="wddx2cfml" input="#qCheckRequest.approval_data#" output="arr_approvaldata">--->
			<cfset local.strckAppr = ApprovalLoop(arr_approvaldata,request.scookie.user.empid)/>
	        <cfset local.userindbstep = strckAppr.empinstep>
			<cfif not listfindnocase(strckAppr.fullapproverlist,requestfor) and listfindnocase(valuelist(qGetSPMH.reviewer_empid),requestfor)>
				<cfset userindbstep++>
	        </cfif>
	        
	        <!--- di wddx, yang akan dihapus "approvedby"-nya adalah --->
			<cfset local.steptosetrevised = 0>
	        <cfif listfindnocase(valuelist(qGetSPMH.review_step),userindbstep) gt 1>
		        <cfset steptosetrevised = listgetat(valuelist(qGetSPMH.review_step),listfindnocase(valuelist(qGetSPMH.review_step),userindbstep)-1)>
	        <cfelseif listlen(valuelist(qGetSPMH.review_step)) gt 0>
	        	<cfset steptosetrevised = listlast(valuelist(qGetSPMH.review_step))>
	        </cfif>
	        <cfif userindbstep - strckAppr.empinstep eq 1 and steptosetrevised eq 1>
	        	<cfset steptosetrevised = 0>
	        <cfelseif userindbstep - strckAppr.empinstep eq 1>
		        <cfset --steptosetrevised>
	        </cfif>

	        <!--- update head status reviewer sebelumnya jadi 0 --->
	     <!---   <cfquery name="local.qUpdHeadStatus" datasource="#request.sdsn#">
	           	UPDATE TPMDPERFORMANCE_EVALH
	            SET head_status = 0
				WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#Form.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
					AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	                <cfif steptosetrevised neq 0>
						AND reviewer_empid IN (
		                	SELECT emp_id FROM TEOMEMPPERSONAL WHERE user_id = <cfqueryparam value="#arr_approvaldata[steptosetrevised].approvedby#" cfsqltype="cf_sql_varchar">
	                    )
	                <cfelse>
						AND reviewer_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	                </cfif>
	        </cfquery> ----->
            
            <!--- TCK0818-81809 --->
        	<cfset variables.sendtype = 'next'>
        	<cfset strckData.isfinal = 0/>
        	<cfset strckData.head_status = 0/>
        	<cfset strckData.isfinal_requestno = 1/>
        	
            <cfset SaveTransaction(50,strckData)/>
			<cfquery name="local.qGetLatestBeforeRevise" datasource="#request.sdsn#">
				SELECT <cfif request.dbdriver eq "MSSQL"> TOP 1 </cfif>
				reviewer_empid FROM TPMDPERFORMANCE_EVALH
				WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
				AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
				AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar"> 
				AND head_status = 1
				AND reviewer_empid <> <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
				ORDER BY created_date desc
				<cfif request.dbdriver eq "MYSQL"> LIMIT 1 </cfif>
			</cfquery>
			<cfif qGetLatestBeforeRevise.reviewer_empid neq "">
				<cfquery name="local.qGetLatestBeforeRevise" datasource="#request.sdsn#">
					SELECT user_id from teomemppersonal where emp_id = '#qGetLatestBeforeRevise.reviewer_empid#'
				</cfquery>
				 <cfset new_outstanding = qGetLatestBeforeRevise.user_id &","&new_outstanding>
			</cfif>
            <!--- TCK0818-81809 --->
	        
	        <!---<cfoutput><script>alert("yan #steptosetrevised# -- #requestfor# -- #form_code# -- #reqno#");</script></cfoutput><CF_SFABORT>--->
	        
	        <cfif steptosetrevised neq 0>
	            <!--- update last reviewer, modified_date untuk revised jadi si user --->
	            <cfquery name="local.qUpdHeadStatus" datasource="#request.sdsn#">
	            	UPDATE TPMDPERFORMANCE_EVALH
	                SET modified_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#Form.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
					AND reviewee_empid = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
					AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>

	        	<cfset local.uidtorevised = arr_approvaldata[steptosetrevised].approvedby>
				<cfset arr_approvaldata[steptosetrevised].approvedby = ""/>
				<cfset LOCAL.new_approvaldata=SFReqFormat(arr_approvaldata,"W")>
	    		<!---TW:<cfwddx action="cfml2wddx" input="#arr_approvaldata#" output="new_approvaldata">
		        <cfset new_outstanding =  uidtorevised&","&new_outstanding/>--->
	            <cfif listlen(new_approved) and listfindnocase(new_approved,uidtorevised)>
	    	    	<cfset new_approved =  listdeleteat(new_approved,listfindnocase(new_approved,uidtorevised))/>
	            </cfif>
	            
	        <cfelse>
	            <cfquery name="local.qGetUserId" datasource="#request.sdsn#">
	            	SELECT DISTINCT user_id FROM TEOMEMPPERSONAL
					WHERE emp_id = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            
		      <!---  <cfset new_outstanding =  qGetUserId.user_id&","&new_outstanding/>--->
	        </cfif>
	        
			<!--- set approved_data --->
			<cfset LOCAL.strckApprovedData=SFReqFormat(qCheckRequest.approved_data,"R")>
			<cfset var strckFormInbox = StructNew() />
			<cfset strckFormInbox['DTIME'] = Now() />
			<cfset strckFormInbox['DECISION'] = 3 />
	        <cfif structkeyexists(FORM,"revisingNotes")>
				<cfset strckFormInbox['NOTES'] = Form.revisingNotes />
	        <cfelse>
				<cfset strckFormInbox['NOTES'] = "-" />
	        </cfif>
			<cfset LOCAL.apvdDataKey = request.scookie.user.uid >
			<cfif trim(qCheckRequest.approved_data) eq '' OR (isStruct(strckApprovedData) AND REFind('_', ListFirst(StructKeyList(strckApprovedData)) ) ) >
				<cfset LOCAL.cntStrckApprovedData = StructCount(strckApprovedData)+1 />
				<cfset apvdDataKey = NumberFormat(cntStrckApprovedData,'00')&'_'&apvdDataKey >
			</cfif>
			<cfset strckApprovedData[apvdDataKey] = strckFormInbox />
			<cfset LOCAL.wddxApprovedData=SFReqFormat(strckApprovedData,"W")>
	    	<!---TW:
			<cfif IsWDDX(qCheckRequest.approved_data)>
				<cfwddx action="wddx2cfml" input="#qCheckRequest.approved_data#" output="strckApprovedData">

				<cfset var strckFormInbox = StructNew() />
				<cfset strckFormInbox['DTIME'] = Now() />
				<cfset strckFormInbox['DECISION'] = 3 />
	            <cfif structkeyexists(FORM,"revisingNotes")>
					<cfset strckFormInbox['NOTES'] = Form.revisingNotes />
	            <cfelse>
					<cfset strckFormInbox['NOTES'] = "-" />
	            </cfif>
	            
				<cfset strckApprovedData[request.scookie.user.uid] = strckFormInbox />
				<cfwddx action="cfml2wddx" input="#strckApprovedData#" output="wddxApprovedData">
			<cfelse>
		       	<cfset strckApprovedData = structnew()>
				<cfset var strckFormInbox = StructNew() />
				<cfset strckFormInbox['DTIME'] = Now() />
				<cfset strckFormInbox['DECISION'] = 3 />
	            <cfif structkeyexists(FORM,"revisingNotes")>
					<cfset strckFormInbox['NOTES'] = Form.revisingNotes />
	            <cfelse>
					<cfset strckFormInbox['NOTES'] = "-" />
	            </cfif>
				<cfset strckApprovedData[request.scookie.user.uid] = strckFormInbox />
				<cfwddx action="cfml2wddx" input="#strckApprovedData#" output="wddxApprovedData">
			</cfif>--->

	        <cfquery name="local.qUpdRequest" datasource="#request.sdsn#">
	   	    	UPDATE TCLTREQUEST SET
	            <!---TW:<cfif isWDDX(wddxApprovedData)></cfif>--->
					approved_data = <cfqueryparam value="#wddxApprovedData#" cfsqltype="cf_sql_varchar">,
		        <cfif steptosetrevised neq 0>
	        	    approval_data = <cfqueryparam value="#new_approvaldata#" cfsqltype="cf_sql_varchar">,
	            	approved_list = <cfqueryparam value="#new_approved#" cfsqltype="cf_sql_varchar">,
	            <cfelse>
	               	approved_list = '',
	            </cfif>
	            outstanding_list = <cfqueryparam value="#new_outstanding#" cfsqltype="cf_sql_varchar">,
	   	        status = 4,
				modified_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
				modified_by = <cfqueryparam value="#REQUEST.SCOOKIE.USER.UNAME#" cfsqltype="cf_sql_varchar">
	       	    WHERE company_id = <cfqueryparam value="#Form.coid#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	    	        AND company_code = <cfqueryparam value="#Form.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
	   		        AND req_type = 'PERFORMANCE.EVALUATION'
	       		    AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	           		AND reqemp = <cfqueryparam value="#requestfor#" cfsqltype="cf_sql_varchar">
					
	   	    </cfquery>
	        
	        <!--- delete record final jika ada --->
	        <cfquery name="local.qDelFinalRec" datasource="#request.sdsn#">
	        	DELETE FROM TPMDPERFORMANCE_FINAL
	            WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
	        </cfquery>
            <cfquery name="LOCAL.qGetDataRequest" datasource="#request.sdsn#">
    			SELECT seq_id, req_no, status,outstanding_list, company_id, email_list, approval_list FROM TCLTREQUEST 
    			WHERE  req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
    		</cfquery> 
    		<!--- <cfset tempSendEmail = ReviseApprovedNotif({mailtmpltRqster="ReviseRequestNotificationTer",mailtmpltRqstee="ReviseRequestNotificationTee",mailtmpltAprvr="ReviseRequestNotification",notiftmpltRqster="7",notiftmpltRqstee="8",notiftmpltAprvr="9",strRequestNo=reqno,iStatusOld=qGetDataRequest.status,lstNextApprover=qGetDataRequest.outstanding_list,requestcoid=qGetDataRequest.company_id,requestId=qGetDataRequest.seq_id,lastOutstanding=ListLast(qGetDataRequest.outstanding_list)})> --->
    	    </cftransaction>
			
			
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully revising request for previous reviewer",true)>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfoutput>
						<script>
							alert("#strMessage#");
							popClose();
							refreshPage();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="1","MSG"="#strMessage#"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
				
				<!--- Notif goes here --->
                <cfif val(FORM.UserInReviewStep)-1 GTE 1 AND val(FORM.UserInReviewStep)-1 LTE Listlen(FORM.FullListAppr) > <!---Validasi ada next approver--->
    		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep)-1 )><!---hanya get list next approver--->

                    <cfset LOCAL.additionalData = StructNew() >
                    <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                    
                    <cfif lstNextApprover NEQ ''>
                        <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                        <cfif lstSendEmail EQ FORM.REVIEWEE_EMPID> <!--- Send by approver to reviewee --->
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalReviseForReviewee', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        <cfelse><!--- Send by approver status not requested --->
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalReviseForApprover', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        </cfif>
                    </cfif>
                </cfif>
				<!--- Notif goes here --->
				
	    </cffunction>
                
	     <cffunction name="DeleteAdjust">
	        <cfset Local.empid = FORM.requestfor>
	        <cfset Local.reqno = FORM.request_no>
	  
	        <cfquery name="local.qGetSPMH" datasource="#request.sdsn#">
	        	SELECT <cfif request.dbdriver EQ "MSSQL">TOP 1</cfif> form_no, reviewer_empid, review_step, score, conclusion FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            AND head_status = 1
				AND isfinal=1
	            ORDER BY created_date  DESC
	            <cfif request.dbdriver NEQ "MSSQL">LIMIT 1</cfif>
	        </cfquery>
	   
	        <cfif len(qGetSPMH.form_no)>
	            <!---TCK2102-0627491 delete adjust --->
	            <cfquery name="local.qCheckIfEverAdjusted" datasource="#request.sdsn#" result='del'>
	        	    delete  FROM TPMDPERFORMANCE_ADJUSTD
	                WHERE form_no = <cfqueryparam value="#qGetSPMH.form_no#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            </cfquery>
				<cfquery name="local.qDelFinalRec" datasource="#request.sdsn#">
	            	DELETE FROM TPMDPERFORMANCE_FINAL
	                WHERE form_no = <cfqueryparam value="#qGetSPMH.form_no#" cfsqltype="cf_sql_varchar">
	                    AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>
				<cfquery name="local.qCheckRequest" datasource="#request.sdsn#">
					SELECT approval_data, approval_list, approved_list, outstanding_list, approved_data FROM TCLTREQUEST
					WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
					AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
					AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">	
				</cfquery>
	            <cfset local.new_outstanding =  qCheckRequest.outstanding_list/>
	            <cfset local.new_approved =  qCheckRequest.approved_list/>
	    		<cfset LOCAL.arr_approvaldata=SFReqFormat(qCheckRequest.approval_data,"R",[])>
	            <cfquery name="local.qUpdHeadStatus" datasource="#request.sdsn#">
	               	UPDATE TPMDPERFORMANCE_EVALH
	                SET head_status = 1, isfinal = 0, 
	                	modified_by = <cfqueryparam value="#request.scookie.user.uname#|UNFINAL" cfsqltype="cf_sql_varchar">,
	                    modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">
	    			WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	    				AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    				AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	    				AND reviewer_empid = <cfqueryparam value="#qGetSPMH.reviewer_empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfset local.uidtorevised = arr_approvaldata[arraylen(arr_approvaldata)].approvedby>
				<cfset arr_approvaldata[arraylen(arr_approvaldata)].approvedby = ""/>
	    		<cfset LOCAL.new_approvaldata=SFReqFormat(arr_approvaldata,"W")>
				 <cfif listlen(new_outstanding)>
	    	        <cfset new_outstanding =  uidtorevised&","&new_outstanding/>
	            <cfelse>
	    	        <cfset new_outstanding =  uidtorevised/>
	            </cfif>
				<cfif listlen(new_approved) AND listfindnocase(new_approved,uidtorevised) LTE listlen(new_approved) AND listfindnocase(new_approved,uidtorevised) GT 0>
	      	    	<cfset new_approved =  listdeleteat(new_approved,listfindnocase(new_approved,uidtorevised))/>
	            </cfif>
	    
	            <cfquery name="local.qUpdRequest" datasource="#request.sdsn#">
	       	    	UPDATE TCLTREQUEST SET
	           	    approval_data = <cfqueryparam value="#new_approvaldata#" cfsqltype="cf_sql_varchar">,
	               	approved_list = <cfqueryparam value="#new_approved#" cfsqltype="cf_sql_varchar">,
	                outstanding_list = <cfqueryparam value="#new_outstanding#" cfsqltype="cf_sql_varchar">,
					modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
	                 modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">,
	       	        status = 2
	           	    WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	        	        AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	       		        AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
	           		    AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	               		AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	    				
	       	    </cfquery>
				
				
	        </cfif>
	            <cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
	                   <cfoutput>
	                        <cfset local.openSuccess = Application.SFParser.TransMLang("FDSuccessfully opening Performance Evaluation Form",true)>
						   <script>
							  alert("#openSuccess#");
							  popClose();
							  refreshPage();   
						   </script>
						</cfoutput> 
	            <cfelse>
	            
	                <cfscript>
			            data = {"success"="3"};
		            </cfscript>
					<cfoutput>
						#SerializeJSON(data)#
	                </cfoutput>
	            </cfif>
	        
	            
	   </cffunction>
	    <cffunction name="UnfinalPerfEvalForm">
	        <cfset Local.empid = FORM.requestfor>
	        <cfset Local.reqno = FORM.request_no>
	       	<cfset Local.error_found = 0>
	        <cfquery name="local.qCheckRequest" datasource="#request.sdsn#">
	        	SELECT approval_data, approval_list, approved_list, outstanding_list, approved_data FROM TCLTREQUEST
	            WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
	            AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">	
	        </cfquery>
	        
	        <cfquery name="local.qGetSPMH" datasource="#request.sdsn#">
	        	SELECT <cfif request.dbdriver EQ "MSSQL">TOP 1</cfif> form_no, reviewer_empid, review_step FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            AND head_status = 1
	            ORDER BY review_step DESC
	            <cfif request.dbdriver NEQ "MSSQL">LIMIT 1</cfif>
	        </cfquery>
	                
	         <cfquery name="local.qCheckIfEverAdjusted" datasource="#request.sdsn#">
	        	SELECT adjust_no FROM TPMDPERFORMANCE_FINAL
	            WHERE form_no = <cfqueryparam value="#qGetSPMH.form_no#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	   
	        <cfif not len(qCheckIfEverAdjusted.adjust_no)>
	            <cfquery name="local.qDelFinalRec" datasource="#request.sdsn#">
	            	DELETE FROM TPMDPERFORMANCE_FINAL
	                WHERE form_no = <cfqueryparam value="#qGetSPMH.form_no#" cfsqltype="cf_sql_varchar">
	                    AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	    
	            <cfset local.new_outstanding =  qCheckRequest.outstanding_list/>
	            <cfset local.new_approved =  qCheckRequest.approved_list/>
	    		<cfset LOCAL.arr_approvaldata=SFReqFormat(qCheckRequest.approval_data,"R",[])>
	            <cfquery name="local.qUpdHeadStatus" datasource="#request.sdsn#">
	               	UPDATE TPMDPERFORMANCE_EVALH
	                SET head_status = 1, isfinal = 0, 
	                	modified_by = <cfqueryparam value="#request.scookie.user.uname#|UNFINAL" cfsqltype="cf_sql_varchar">,
	                    modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">
	    			WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	    				AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    				AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	    				AND reviewer_empid = <cfqueryparam value="#qGetSPMH.reviewer_empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfset local.uidtorevised = arr_approvaldata[arraylen(arr_approvaldata)].approvedby>
				<cfset arr_approvaldata[arraylen(arr_approvaldata)].approvedby = ""/>
	    		<cfset LOCAL.new_approvaldata=SFReqFormat(arr_approvaldata,"W")>
				 <cfif listlen(new_outstanding)>
	    	        <cfset new_outstanding =  uidtorevised&","&new_outstanding/>
	            <cfelse>
	    	        <cfset new_outstanding =  uidtorevised/>
	            </cfif>
				<cfif listlen(new_approved) AND listfindnocase(new_approved,uidtorevised) LTE listlen(new_approved) AND listfindnocase(new_approved,uidtorevised) GT 0>
	      	    	<cfset new_approved =  listdeleteat(new_approved,listfindnocase(new_approved,uidtorevised))/>
	            </cfif>
	    
	            <cfquery name="local.qUpdRequest" datasource="#request.sdsn#">
	       	    	UPDATE TCLTREQUEST SET
	           	    approval_data = <cfqueryparam value="#new_approvaldata#" cfsqltype="cf_sql_varchar">,
	               	approved_list = <cfqueryparam value="#new_approved#" cfsqltype="cf_sql_varchar">,
	                outstanding_list = <cfqueryparam value="#new_outstanding#" cfsqltype="cf_sql_varchar">,
					modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
	                 modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">,
	       	        status = 2
	           	    WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	        	        AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	       		        AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
	           		    AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	               		AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	    				
	       	    </cfquery>
	       	<cfelse>
	       	       <!---TCK2102-0627491 Jika ada conclusion adjustment maka akan delete adjustment di function deleteadjust di mainload.xml --->
	            <cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
	        		<cfset local.alertMessageOpenForm1 = Application.SFParser.TransMLang("JSThis employee has already in Performance Conclusion Adjustment process, are you sure want to re-open this form",true)>
	        	    <cfset local.alertMessageOpenForm2 = Application.SFParser.TransMLang("JSFailed opening Performance Evaluation Form",true)>
	        	    
	        	    <cfoutput>
						<script>
							var b = confirm("#alertMessageOpenForm1# ?");
							if(b == true){
							   
									parent.deleteAdjust(); 
	                            
	                           }else{
							       alert("#alertMessageOpenForm2#");
									popClose();
									refreshPage();   
								}
					
						</script>
					</cfoutput>
				<cfelse>
					<cfset error_found = 2>
				</cfif>
	        </cfif>
	            
	      
	        
			<cfif not error_found>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("FDSuccessfully opening Performance Evaluation Form",true)>
			<cfelseif error_found eq 2>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSThis employee has already in Performance Conclusion Adjustment process, are you sure want to re-open this form",true)>
			<cfelse>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed opening Performance Evaluation Form",true)>
	        </cfif>
	        

			
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
	        
	        	     <cfif not len(qCheckIfEverAdjusted.adjust_no)>
						<cfoutput>
							<script>
							    alert("#LOCAL.SFLANG#");
								popClose();
								refreshPage();
							</script>
						</cfoutput>
					 </cfif>
					
					
	        	    
    			    <!--- Notif goes here --->
                    <cfif val(FORM.UserInReviewStep) GTE 1 AND val(FORM.UserInReviewStep) LTE Listlen(FORM.FullListAppr) > <!---Validasi ada next approver--->
        		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep) )><!---hanya get list next approver--->
    
                        <cfset LOCAL.additionalData = StructNew() >
                        <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                        
                        <cfif lstNextApprover NEQ ''>
                            <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalNotifOpenForm', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        </cfif>
                    </cfif>
    			    <!--- Notif goes here --->	

				<cfelse>
				
					<cfif not error_found>
						<cfscript>
							data = {"success"="1","request_no"="#reqno#","form_no"="#qGetSPMH.form_no#"};
						</cfscript>
    						
        			    <!--- Notif goes here --->
		       		    <cfset local.strckListApprover = GetApproverList(reqno=reqno,empid=empid,reqorder='-',varcoid=REQUEST.SCOOKIE.COID,varcocode=REQUEST.SCOOKIE.COCODE)>

                        <cfif val(strckListApprover.index) GTE 1 AND val(strckListApprover.index) LTE Listlen(strckListApprover.FullListApprover) > <!---Validasi ada next approver--->
            		        <cfset LOCAL.lstNextApprover = ListGetAt( strckListApprover.FullListApprover , val(strckListApprover.index) )><!---hanya get list next approver--->
        
                            <cfset LOCAL.additionalData = StructNew() >
                            <cfset additionalData['REQUEST_NO'] = reqno ><!---Additional Param Untuk template--->
                            
                            <cfif lstNextApprover NEQ ''>
                                <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                    template_code = 'PerformanceEvalNotifOpenForm', 
                                    lstsendTo_empid = lstSendEmail , 
                                    reviewee_empid = empid ,
                                    strckData = additionalData
                                )>
                            </cfif>
                        </cfif>
        			    <!--- Notif goes here --->	
					<cfelseif error_found eq 2>
						<cfscript>
					    	data = {"success"="2","MSG"="#SFLANG#"};
					    </cfscript>	
					<cfelse>
					    <cfscript>
							data = {"success"="0","MSG"="#SFLANG#"};
						</cfscript>
					
					</cfif>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
    				
					
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
			
	    	
	    </cffunction>
	   
          <cffunction name="DeleteFormAsDraft">
	    	<cfset local.strckData = structnew()>
	        <cfset strckData.reviewee_empid = FORM.requestfor>
	        <cfset strckData.request_no = FORM.request_no>
	        <cfset strckData.formno = FORM.formno>
	        <cfset strckData.period_code = FORM.period_code>
	        <cfset strckData.reference_date = FORM.reference_date>

	        <cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>  <!--- TCK0618-81679 ----->
	        
	        <cftry>
	        
				<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALNOTE
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
				    AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALD
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				    AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				    
	            </cfquery>
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
	            	DELETE FROM TPMDPERFORMANCE_EVALH
					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
	                AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
	                <!--- AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				    AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
	             </cfquery>
	            
    					<cfquery name="Local.qPMCheck2" datasource="#request.sdsn#">
        					select head_status from TPMDPERFORMANCE_EVALH
        					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
        					AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
        					AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
        					<!--- AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
        					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
        					AND reviewer_empid <> <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
    					</cfquery>
    					<cfif ReturnVarCheckCompParam eq true>
    					    <cfif qPMCheck2.recordcount eq 0 >
    					     
    					    <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
    					     UPDATE TCLTREQUEST
    					    	    SET status = 1
    						        WHERE req_type = 'PERFORMANCE.EVALUATION'
    						        AND req_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    						        AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    						       </cfquery>
    						 </cfif>      
    		            </cfif>	
    			
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="1"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
	        <cfcatch>
				<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset strMessage = Application.SFParser.TransMLang("JSFailed Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="0"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
	        	
	        </cfcatch>
	        </cftry>
	    </cffunction>
	    <cffunction name="DeleteReqForm">
	    	<cfset local.strckData = structnew()>
	        <cfset strckData.reviewee_empid = FORM.requestfor>
	        <cfset strckData.request_no = FORM.request_no>
	        <cfset strckData.formno = FORM.formno>
	        <cfset strckData.period_code = FORM.period_code>
	        <cfset strckData.reference_date = FORM.reference_date>
	        
	        <cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>  <!--- TCK0618-81679 ----->

	        <cftry>
	        	<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALNOTE
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
					    <cfif ReturnVarCheckCompParam eq true> <!--- delete per reviewer draft --->
				            AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				        </cfif>
	            </cfquery>
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
					DELETE FROM TPMDPERFORMANCE_EVALD
					WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					    <cfif ReturnVarCheckCompParam eq true> <!--- delete per reviewer draft --->
				            AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				        </cfif>
	            </cfquery>
	            	<cfquery name="Local.qPMCheck" datasource="#request.sdsn#">
        				select head_status from TPMDPERFORMANCE_EVALH
        				WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
                        AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                        AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
                        <!--- AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
                        AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
        				AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
    				</cfquery>
	            	<cfquery name="Local.qPMCheck2" datasource="#request.sdsn#">
        					select head_status from TPMDPERFORMANCE_EVALH
        					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
        					AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
        					AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
        					<!--- AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
        					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
        					AND reviewer_empid <> <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
    					</cfquery>
    						<cfquery name="Local.delevalattach" datasource="#request.sdsn#" result='deleval'>
    					   delete from TPMDPERF_EVALATTACHMENT
    					    where form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                            AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
                           
                            AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
        				   <cfif qPMCheck.head_status eq 0 and qPMCheck2.recordcount neq 0>
                                AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
        				       
        				   </cfif>
    					 
    					</cfquery>
    					<cfif  qPMCheck2.recordcount eq 0>
    					    <cfquery name="Local.delevalattach" datasource="#request.sdsn#" result='delcomp'>
                                delete from TPMDEVALD_COMPPOINT  
                                where form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                                and request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
                            </cfquery>
    					</cfif>
    				  
	            <!---Delete EvalKPI--->
    			<cfif ReturnVarCheckCompParam eq false>
    				<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">	
    					DELETE FROM TPMDPERFORMANCE_EVALKPI
    					WHERE  period_code = <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
    					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    				</cfquery>
    				 
    			<cfelse>
    			
    	            <cfif qPMCheck.head_status eq 0>
    					<cfquery name="Local.qPMCheck2" datasource="#request.sdsn#">
        					select head_status from TPMDPERFORMANCE_EVALH
        					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
        					AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
        					AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
        					<!--- AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
        					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
        					AND reviewer_empid <> <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
    					</cfquery>
    			
    					<cfif qPMCheck2.recordcount eq 0>
    						<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">	
    							DELETE FROM TPMDPERFORMANCE_EVALKPI
    							WHERE period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
    							AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    						</cfquery>
    					</cfif>
    				</cfif>
    			</cfif>
	            <!---Delete EvalKPI--->
	            
	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
	            	DELETE FROM TPMDPERFORMANCE_EVALH
					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
	                AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
	                AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
	                <!--- AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					    <cfif ReturnVarCheckCompParam eq true> <!--- delete per reviewer draft --->
				            AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
				        </cfif>
	            </cfquery>
	            
	            <cfif ReturnVarCheckCompParam eq false>
    	            <cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
    					DELETE FROM TCLTREQUEST
    					WHERE req_type = 'PERFORMANCE.EVALUATION'
    					AND req_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    	                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    	            </cfquery>
    	        <cfelse>
    				<cfquery name="Local.qPMCheck2" datasource="#request.sdsn#">
    					select request_no from TPMDPERFORMANCE_EVALH
    					WHERE request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    					AND form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
    					AND period_code =  <cfqueryparam value="#strckData.period_code#" cfsqltype="cf_sql_varchar">
    					<!--- AND reference_date = <cfqueryparam value="#strckData.reference_date#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
    					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    				
    				</cfquery>
    				<cfif qPMCheck2.recordcount eq 0>
    					<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
    						UPDATE TCLTREQUEST
    						SET status = 1
    						WHERE req_type = 'PERFORMANCE.EVALUATION'
    						AND req_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
    						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
    					</cfquery>
    				</cfif>
    	        </cfif>
				
				<!---- start Condition : New Layout Performance Evaluation Form  ------>
	        	<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="1"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
				<!---- End Condition : New Layout Performance Evaluation Form  ------>
				
	        <cfcatch>
				<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
					<cfset strMessage = Application.SFParser.TransMLang("JSFailed Deleting Performance Form Request", true)>
					<cfoutput>
						<script>
							alert("#strMessage#");
							parent.refreshPage();
							parent.popClose();
						</script>
					</cfoutput>
				<cfelse>
					<cfscript>
						data = {"success"="0"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
	        	
	        </cfcatch>
	        </cftry>
	    </cffunction>
	    
	   <cffunction name="Inbox"> 
			<cfargument name="RequestData" type="Struct" required="Yes">
			<cfargument name="ProcData" type="array" required="Yes">
			<cfargument name="RowNumber" type="Numeric" required="Yes">
			<cfargument name="RequestMode" type="String" required="Yes">
			<cfargument name="RequestStatus" type="Numeric" required="Yes">
			<cfargument name="RequestKey" type="String" required="No">
			  <!---start : ENC51115-79853--->
			<cfargument name="varcoid" required="No" default="#request.scookie.coid#"> 
			<cfargument name="varcocode" required="No" default="#request.scookie.cocode#">
			 <!---end : ENC51115-79853--->
			<cfset LOCAL.SFMLANG=Application.SFParser.TransMLang(listAppend("FDLink|FDRemark|View Performance Evaluation Form|FDLastReviewer|Previous Step Reviewer",(isdefined("FORMMLANG")?FORMMLANG:""),"|"))>
		
	        <cfset Local.reqorder = "inbox">
			<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			<cfif ReturnVarCheckCompParam eq false >
				<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
					<cfset Local.reqorder = getApprovalOrder(reviewee=Arguments.RequestData.EMP_ID,reviewer=request.scookie.user.empid)> 
				 <cfelse>
					<cfset Local.reqorder = getApprovalOrder(reviewee=Arguments.RequestData.requestfor,reviewer=request.scookie.user.empid)> 
				 </cfif>
			<cfelse>
				 <cfset Local.reqorder = "-">
			</cfif>
	       
			<cfset LOCAL.scProc=Arguments.ProcData>
	        <cfquery name="Local.qGetAllParam" datasource="#request.sdsn#">
	        	SELECT  p.emp_id, c.grade_code, c.position_id  FROM  TEODEMPCOMPANY c
				INNER JOIN TEOMEMPPERSONAL p ON c.emp_id = p.emp_id
				 <cfif not structkeyexists(Arguments.RequestData,"requestfor")>
					WHERE c.emp_id = <cfqueryparam value="#Arguments.RequestData.EMP_ID#" cfsqltype="cf_sql_varchar">
				 <cfelse>
					WHERE c.emp_id = <cfqueryparam value="#Arguments.RequestData.requestfor#" cfsqltype="cf_sql_varchar">
				 </cfif>
	        </cfquery>
	        <cfquery name="Local.qGetFormNo" datasource="#request.sdsn#">
	        	SELECT  form_no, reviewer_empid, head_status, modified_date FROM TPMDPERFORMANCE_EVALH
	            WHERE request_no = <cfqueryparam value="#Arguments.RequestData.request_no#" cfsqltype="cf_sql_varchar">
	            AND period_code = <cfqueryparam value="#Arguments.RequestData.period_code#" cfsqltype="cf_sql_varchar">
				<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
					AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.EMP_ID#" cfsqltype="cf_sql_varchar">
				<cfelse>
					AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.requestfor#" cfsqltype="cf_sql_varchar">
				</cfif>
	            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            <!--- and head_status = 1  Bugs draft tidak dapat formno ketika non pregen --->
				order by review_step desc
	        </cfquery>

			<!---Get last reviewer--->
			<cfset local.infoLastReviewer = " : -">
			<cfquery name="LOCAL.qGetLastApproved" dbtype="query">
			    SELECT * FROM qGetFormNo
			    WHERE head_status = 1
			</cfquery>
			<cfif qGetLastApproved.REVIEWER_EMPID neq ''>
				<cfquery name="Local.qGetinfoName" datasource="#request.sdsn#">
    				SELECT p.full_name , c.emp_no  FROM  TEODEMPCOMPANY c
    				INNER JOIN TEOMEMPPERSONAL p
    					ON c.emp_id = p.emp_id
    				WHERE c.emp_id = <cfqueryparam value="#qGetFormNo.REVIEWER_EMPID#" cfsqltype="cf_sql_varchar">
				</cfquery>
				<cfset infoLastReviewer = ' : #qGetinfoName.full_name#  <span class="req-date" style="float: unset;"> #dateformat(qGetLastApproved.modified_date,"d mmm yyyy")# (#timeformat(qGetLastApproved.modified_date,"HH:mm")#) </span> '>
			</cfif>
			<!---Get last reviewer--->
	        

			<cfif qGetFormNo.recordcount eq 0>
				 <cfquery name="Local.qGetFormNo" datasource="#request.sdsn#">
					SELECT  form_no, reviewer_empid FROM TPMDPERFORMANCE_EVALGEN
					WHERE req_no = <cfqueryparam value="#Arguments.RequestData.request_no#" cfsqltype="cf_sql_varchar">
					AND period_code = <cfqueryparam value="#Arguments.RequestData.period_code#" cfsqltype="cf_sql_varchar">
					<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
						AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.EMP_ID#" cfsqltype="cf_sql_varchar">
					<cfelse>
						AND reviewee_empid = <cfqueryparam value="#Arguments.RequestData.requestfor#" cfsqltype="cf_sql_varchar">
					</cfif>
					AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
				  </cfquery>
			</cfif>
			
			
			<!---Get current Period Info--->
			<cfquery name="Local.qGetPeriodInf" datasource="#request.sdsn#">
                SELECT  P.period_name_#request.scookie.lang# AS period_name, P.reference_date
				FROM TPMMPERIOD P
				WHERE P.period_code = <cfqueryparam value="#Arguments.RequestData.period_code#" cfsqltype="cf_sql_varchar">
					AND P.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset LOCAL.CurrentRefDate = DateFormat(qGetPeriodInf.reference_date,'yyyy-mm-dd') >
			<!---Get current Period Info--->
			
			
			<cfset local.ibxlabel="background-color:##e9e9e9;padding:2px 5px;border-bottom: 1px solid black; border-right:0px;">
			<cfset local.ibxdata="background-color:##fff;padding:2px 5px;border-bottom: 1px solid black; border-right:0px;">
	        
			<cfoutput>
				#LOCAL.SFMLANG.PreviousStepReviewer##infoLastReviewer#
				<br/><br>
	            <style>
					##linktoperformanceform a span {
						display: inline;
						padding: 8px 9px;
					}
					##linktoperformanceform a{
						color: black;
						font-weight: bold;
						cursor: pointer;
						text-decoration:underline;
					}
				</style>
	            <div id="linktoperformanceform">
				
					<cfif not structkeyexists(Arguments.RequestData,"requestfor")>
						<cfif val(REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE) EQ 1>
							<a href="?sfid=hrm.performance.evalform.newlayout.viewevalform&empid=#Arguments.RequestData.EMP_ID#&periodcode=#Arguments.RequestData.period_code#&refdate=#CurrentRefDate#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						<cfelse>
							<a href="?xfid=hrm.performance.evalform.mainload&empid=#Arguments.RequestData.EMP_ID#&periodcode=#Arguments.RequestData.period_code#&refdate=#CurrentRefDate#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						</cfif>
					<cfelse>
						<cfif val(REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE) EQ 1>
							<a href="?sfid=hrm.performance.evalform.newlayout.viewevalform&empid=#Arguments.RequestData.requestfor#&periodcode=#Arguments.RequestData.period_code#&refdate=#CurrentRefDate#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						<cfelse>
							<a href="?xfid=hrm.performance.evalform.mainload&empid=#Arguments.RequestData.requestfor#&periodcode=#Arguments.RequestData.period_code#&refdate=#CurrentRefDate#&formno=#qGetFormNo.form_no#&amp;reqno=#Arguments.RequestData.request_no#&planformno=&reqorder=#reqorder#&amp;varcoid=#request.scookie.coid#&amp;varcocode=#request.scookie.cocode#"><span>#LOCAL.SFMLANG.ViewPerformanceEvaluationForm#</span></a>
						</cfif>
					</cfif>
					
	               
	            </div>
				<br />
			</cfoutput>
			<cfreturn scProc>
		</cffunction>
	    
	    
		
	    <!--- ambil list lookup score --->
	    <cffunction name="getLookUpScoreList">
	    	<cfargument name="lookupcode" default="">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="componentcode" default="">
	        <cfargument name="refdate" default="">
			<cfquery name="local.qGetLookup" datasource="#request.sdsn#">
		        SELECT  ML.method, ML.symbol, DL.lookup_score, DL.lookup_value
				FROM TPMDLOOKUP DL
					INNER JOIN TPMMLOOKUP ML ON ML.lookup_code = DL.lookup_code AND ML.period_code = DL.period_code AND ML.company_code = DL.company_code
					INNER JOIN TPMDPERIODCOMPONENT C ON C.period_code = ML.period_code AND C.company_code = C.company_code
	                	<!--- <cfif not len(refdate)>
						AND C.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                    </cfif>
	                    --remove join or where reference_date --->
				WHERE C.lookup_code = <cfqueryparam value="#arguments.lookupcode#" cfsqltype="cf_sql_varchar">
					AND C.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND C.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND C.component_code = <cfqueryparam value="#arguments.componentcode#" cfsqltype="cf_sql_varchar">
			</cfquery>
	        
	        <cfreturn qGetLookup>
	    </cffunction>

	    <!--- ambil data-data period --->
	    <cffunction name="getPeriodData">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
				SELECT  P.period_name_#request.scookie.lang# AS period_name, P.reference_date, P.final_startdate, P.final_enddate, P.conclusion_lookup, P.score_type, P.period_startdate, P.period_enddate, P.gauge_type, P.usenormalcurve
				FROM TPMMPERIOD P
				WHERE P.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					<!--- AND P.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
					AND P.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	        <cfreturn qData>
	    </cffunction>

	    <!--- fungsi ini buat ambil bobot komponen period, baik untuk posisi tersebut ada atau tidak (ambil dari yang general) --->
	    <cffunction name="getPeriodCompData">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="posid" default="">
	        <cfargument name="compcode" default="">
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT DISTINCT PC.component_code,
				lookup_scoretype, lookup_total, <!---- added by ENC51017-81177 --->
	            	<cfif len(arguments.posid)>
					CASE WHEN CPW.weight IS NOT NULL THEN CPW.weight ELSE PC.weight END weight
	                <cfelse>
	                PC.weight
	                </cfif>
				FROM TPMDPERIODCOMPONENT PC

	           	<cfif len(arguments.posid)>
				LEFT JOIN TPMDPERIODCOMPPOSWEIGHT CPW 
					ON CPW.period_code = PC.period_code 
					<!--- AND CPW.reference_date = PC.reference_date --remove join or where reference_date ---> 
					AND CPW.component_code = PC.component_code
					AND CPW.company_code = PC.company_code
					AND CPW.position_id = <cfqueryparam value="#arguments.posid#" cfsqltype="cf_sql_integer">
	            </cfif>
	            
				WHERE PC.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	            	<!--- AND PC.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
	                <cfif len(arguments.compcode)>
	                	AND PC.component_code = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                </cfif>
	        </cfquery>
		
	        <cfreturn qData>
	    </cffunction>

	    <cffunction name="getReqEmpData">
	        <cfargument name="reqno" default="">
	        <cfargument name="formno" default="">
	        <cfargument name="empid" default="">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="compcode" default=""> <!--- ALL / COMPONENT / APPRAISAL / PERSKPI / ORGKPI / COMPETENCY --->
	        <cfargument name="libcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT EH.form_no, ED.lib_code, ED.lib_type, ED.achievement, 
	        	    case when ED.score is null then 0 else ED.score end score, 
	        	    case when ED.weightedscore is null then 0 else ED.weightedscore end weightedscore, 
	        	    case when ED.weight is null then 0 else ED.weight end weight,
	        	    ED.target, ED.notes
					,ED.reviewer_empid ,EH.score AS conscore, EH.conclusion
				FROM TPMDPERFORMANCE_EVALH EH
				LEFT JOIN TPMDPERFORMANCE_EVALD ED 
	            	ON ED.form_no = EH.form_no 
	                AND ED.company_code = EH.company_code 
	   	            AND ED.reviewer_empid = EH.reviewer_empid
				WHERE EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
					AND EH.reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
					AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					<!--- AND EH.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
					AND EH.reviewer_empid IN (<cfqueryparam value="#arguments.reviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	   	            AND ED.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
					AND ED.lib_type = <cfqueryparam value="COMPONENT" cfsqltype="cf_sql_varchar">
	                <cfif len(arguments.libcode)>
						AND ED.lib_code = <cfqueryparam value="#arguments.libcode#" cfsqltype="cf_sql_varchar">
	                </cfif>
	   	    </cfquery>
	           
	        <cfreturn qData>
	    </cffunction>

	    <cffunction name="getActualAndScoreType">
	    	<cfargument name="periodcode" default="">
	    	<cfargument name="compcode" default="">
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
			
	        <cfquery name="Local.qGetType" datasource="#request.sdsn#">
	        	SELECT P.conclusion_lookup, PC.component_code, PC.actual_type, PC.lookup_code,
				<!---- Start : ENC51017-81177 --->
				CASE WHEN PC.lookup_scoretype <> '0' AND  PC.lookup_scoretype <> '' THEN PC.lookup_scoretype ELSE P.score_type END AS score_type
			
				<!---- end : ENC51017-81177 --->
				FROM TPMMPERIOD P
				INNER JOIN TPMDPERIODCOMPONENT PC 
					ON PC.period_code = P.period_code 
					AND PC.company_code = P.company_code 
					<!--- AND PC.reference_date = P.reference_date --remove join or where reference_date --->
				WHERE P.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND P.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	                <cfif len(arguments.compcode)>
	                AND PC.component_code = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                </cfif>
	        </cfquery>
	        <cfreturn qGetType>
	    </cffunction>

	    <cffunction name="getScoringDetail">
	    	<cfargument name="scorecode" default="">
	    	<cfargument name="complibcode" default=""> <!--- untuk competency lib --->
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No"> <!--- ENC51115-79853 --->
			
	        <cfif len(scorecode)>
		    	<cfquery name="local.qGetScDet" datasource="#request.sdsn#">
		        	SELECT S.score_type,
		        	    <cfif request.dbdriver eq "MSSQL"> 
		        	    '['+CONVERT(varchar,scoredet_value)+'] '+ SD.scoredet_mask AS opttext, 
		        	    <cfelse>
		        	    '['||CONVERT(scoredet_value,char)||'] '|| coalesce(SD.scoredet_mask,'') AS opttext, 
		        	    </cfif>
	                	SD.scoredet_value AS optvalue, SD.scoredet_value, SD.scoredet_desc, SD.scoredet_mask
					FROM TGEMSCORE S
					INNER JOIN TGEDSCOREDET SD ON SD.score_code = S.score_code AND SD.company_code = S.company_code
					WHERE S.score_code = <cfqueryparam value="#arguments.scorecode#" cfsqltype="cf_sql_varchar">
						AND S.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					ORDER BY SD.scoredet_value
		        </cfquery>
				<cfreturn qGetScDet>
				
	      <cfelseif len(complibcode)>

		    	<cfquery name="local.qGetScDet" datasource="#request.sdsn#">
	            	SELECT 'L' score_type, point_value AS optvalue, 
	            	<cfif request.dbdriver eq "MSSQL"> 
	            	'['+CONVERT(varchar,point_value)+'] '+ point_name_#request.scookie.lang# AS opttext
	            	<cfelse>
	            	'['||CONVERT(point_value,char)||'] '|| point_name_#request.scookie.lang# AS opttext
	            	</cfif>
					FROM TPMDCOMPETENCEPOINT
					WHERE competence_code = <cfqueryparam value="#arguments.complibcode#" cfsqltype="cf_sql_varchar">
					ORDER BY point_value
		        </cfquery>
				<cfreturn qGetScDet> 
	        </cfif>
	        
	        
	    </cffunction>
	    
		
		
		
		
		
		

	    <cffunction name="getJSONForLookUp">
	    	<cfargument name="periodcode" default="">
	        <cfargument name="lookupcode" default="">
	        <cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
	        <cfset Local.strckLookData = structnew()>
	        <cfset Local.strckReturnData = structnew()>
	        <cfset local.strckTemp = structnew()>

	        <cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
				SELECT  M.method, M.symbol
				FROM TPMMLOOKUP M 
				WHERE M.lookup_code = <cfqueryparam value="#lookupcode#" cfsqltype="cf_sql_varchar">
					AND M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			</cfquery>
			
			<cfif qGetLookUpDetail.recordcount eq 0>
				<cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
					SELECT  M.method, M.symbol
					FROM TPMMLOOKUP M 
					WHERE M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
						AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				</cfquery>
			
			</cfif>

	        <cfset strckTemp["method"] = qGetLookUpDetail.method>
	        <cfset strckTemp["symbol"] = qGetLookUpDetail.symbol>
	        
	        <cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
				<!---
				ada ubah PK di TPMDLOOKUP
				SELECT D.lookup_value AS returnval, D.lookup_score AS lookval, M.method, M.symbol
				--->
				SELECT D.lookup_score AS returnval, D.lookup_value AS lookval, M.method, M.symbol
				FROM TPMMLOOKUP M 
				INNER JOIN TPMDLOOKUP D 
			    	ON D.lookup_code = M.lookup_code 
			        AND D.period_code = M.period_code 
			        AND D.company_code = M.company_code
				WHERE M.lookup_code = <cfqueryparam value="#lookupcode#" cfsqltype="cf_sql_varchar">
					AND M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				ORDER BY <cfif request.dbdriver eq "MSSQL">CONVERT(FLOAT,D.lookup_value)<cfelse>CONVERT(D.lookup_value,DOUBLE)</cfif> <cfif listfindnocase("LT,LTE",ucase(strckTemp.symbol))>ASC<cfelseif listfindnocase("GT,GTE",ucase(strckTemp.symbol))>DESC</cfif>
			</cfquery>
			
			<cfif qGetLookUpDetail.recordcount eq 0>
				<cfquery name="local.qGetLookUpDetail" datasource="#request.sdsn#">
					<!---
					ada ubah PK di TPMDLOOKUP
					SELECT D.lookup_value AS returnval, D.lookup_score AS lookval, M.method, M.symbol
					--->
					SELECT D.lookup_score AS returnval, D.lookup_value AS lookval, M.method, M.symbol
					FROM TPMMLOOKUP M 
					INNER JOIN TPMDLOOKUP D 
						ON D.lookup_code = M.lookup_code 
						AND D.period_code = M.period_code 
						AND D.company_code = M.company_code
					WHERE M.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
						AND M.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					<!---ORDER BY <cfif request.dbdriver eq "MSSQL">CONVERT(FLOAT,D.lookup_value)<cfelse>CONVERT(D.lookup_value,DOUBLE)</cfif> <cfif listfindnocase("LT,LTE",ucase(strckTemp.symbol))>ASC<cfelseif listfindnocase("GT,GTE",ucase(strckTemp.symbol))>DESC</cfif> --->
				</cfquery>
				
			</cfif>

	        <cfloop query="qGetLookUpDetail">
	        	<cfset strckLookData["#currentrow#"] = lookval>
	        	<cfset strckReturnData["#currentrow#"] = returnval>
	        	
	        </cfloop>
	        <cfset strckTemp["look"] = strckLookData>
	        <cfset strckTemp["return"] = strckReturnData>
	       
	       	<cfreturn serializeJSON(strckTemp)>
			
	    </cffunction>
	    
	    <cffunction name="getEmpName">
	    	<cfparam name="empid" default="">

			<cfquery name="local.qGetEmp" datasource="#request.sdsn#">
				SELECT DISTINCT full_name + ' [' + emp_no + ']' empname
				FROM TEOMEMPPERSONAL join TEODEMPCOMPANY on TEOMEMPPERSONAL.emp_id = TEODEMPCOMPANY.emp_id
				AND TEOMEMPPERSONAL.emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetEmp>
		</cffunction>
		
		<cffunction name="getEmpLogin">
	    	<cfargument name="empid" default="">

			<cfquery name="local.qGetEmp" datasource="#request.sdsn#">
				SELECT DISTINCT full_name
				FROM TEOMEMPPERSONAL
				WHERE emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetEmp.full_name>
		</cffunction>
		
		<cffunction name="TaskDash">
	    	<cfargument name="empid" default="">
			<cfargument name="startdate" default="">
			<cfargument name="enddate" default="">
			<cfargument name="chkstat" default="6">
			
			<cfif len(trim(startdate)) eq 0>
				<cfset startdate = createdate(year(now()),1,1)>			
			</cfif>

			<cfif len(trim(enddate)) eq 0>
				<cfset enddate = createdate(year(now()),12,31)>			
			</cfif>
			
	        <cfquery name="local.qGetTaskListing" datasource="#request.sdsn#">
	        	SELECT  TK.task_code, EP.full_name AS asignee_name, TK.task_desc, TK.priority, TK.status, TK.startdate, TK.duedate, GBY.full_name AS givenby, TK.status_task, TK.completion_date, TK.created_task
				FROM TPMDTASK TK
				INNER JOIN TEOMEMPPERSONAL GBY
					ON GBY.emp_id = TK.created_task
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = TK.assignee 
					AND TK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND TK.assignee = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
				WHERE TK.duedate >= <cfqueryparam value="#startdate#" cfsqltype="cf_sql_timestamp">
				AND TK.duedate <= <cfqueryparam value="#enddate#" cfsqltype="cf_sql_timestamp">
				<cfif chkstat neq 6>
					AND TK.status_task IN (<cfqueryparam value="#chkstat#" cfsqltype="cf_sql_varchar" list="yes">)
				</cfif>
				ORDER BY duedate, startdate, GBY.full_name
	        </cfquery>
	        <cfreturn qGetTaskListing>
	    </cffunction>
		
		<cffunction name="FeedbackDash">
	    	<cfargument name="empid" default="">
			<cfargument name="startdate" default="">
			<cfargument name="enddate" default="">
			<cfargument name="chkFeedback" default="6">
			
			<cfif len(trim(startdate)) eq 0>
				<cfset startdate = createdate(year(now()),1,1)>			
			</cfif>

			<cfif len(trim(enddate)) eq 0>
				<cfset enddate = createdate(year(now()),12,31)>			
			</cfif>

	        <cfquery name="local.qGetFeedbackListing" datasource="#request.sdsn#">
	        	SELECT  FB.feedback_code, EP.full_name AS asignee_name, FB.feedback_type, FB.feedback_desc, FB.severity_level, FB.status, FB.created_date, GBY.full_name AS givenby, FB.created_feedback
				FROM TPMDFEEDBACK FB
				INNER JOIN TEOMEMPPERSONAL GBY
					ON GBY.emp_id = FB.created_feedback
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = FB.feedback_for
					AND FB.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND FB.feedback_for = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
				WHERE FB.created_date >= <cfqueryparam value="#startdate#" cfsqltype="cf_sql_timestamp">
				AND FB.created_date <= <cfqueryparam value="#enddate#" cfsqltype="cf_sql_timestamp">
				<cfif chkFeedback neq 4>
					AND FB.feedback_type IN (<cfqueryparam value="#chkFeedback#" cfsqltype="cf_sql_varchar" list="yes">)
				</cfif>
				ORDER BY created_date ASC, GBY.full_name
	        </cfquery>

	        <cfreturn qGetFeedbackListing>
	    </cffunction>
		
		<cffunction name="TaskNotes">
	    	<cfparam name="task_code" default="">
			
			<cfquery name="local.qGetTaskListing" datasource="#request.sdsn#">
	        	SELECT DISTINCT TK.task_code, EP.full_name AS asignee_name, TK.task_desc, TK.priority, TK.status, TK.startdate, TK.duedate, GBY.full_name AS empname, TK.status_task, TK.completion_date, TK.created_task
				FROM TPMDTASK TK
				INNER JOIN TEOMEMPPERSONAL GBY
					ON GBY.emp_id = TK.assignee
				INNER JOIN TEOMEMPPERSONAL EP 
					ON EP.emp_id = TK.assignee 
					AND TK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					AND TK.task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">			
	        </cfquery>
	        <cfreturn qGetTaskListing>
	    </cffunction>
		
		<cffunction name="SaveTask">
			<cfoutput>
				<cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("JSTask Desc Is Empty",true)>
				<cfset LOCAL.SFLANG2=Application.SFParser.TransMLang("JSStart Date Is Empty",true)>
				<cfset LOCAL.SFLANG3=Application.SFParser.TransMLang("JSStart Date Is Not In Date Format",true)>
				<cfset LOCAL.SFLANG4=Application.SFParser.TransMLang("JSDue Date Is Empty",true)>
				<cfset LOCAL.SFLANG5=Application.SFParser.TransMLang("JSDue Date Is Not In Date Format",true)>
				<cfset LOCAL.SFLANG6=Application.SFParser.TransMLang("JSCompletion Date Is Not In Date Format",true)>
				<cfset LOCAL.SFLANG7=Application.SFParser.TransMLang("JSCompletion Date Is Empty",true)>
				
				<cftransaction>
					<cfloop from="1" to="#hdn_totalrow#" index="local.idx">
						<cfif isdefined("task_code_#idx#")>
							<cfset local.task_code = evaluate("task_code_#idx#")>
							<cfset local.task_desc = evaluate("task_desc_#idx#")>
							<cfset local.start_date = evaluate("startdate_#idx#")>
							<cfset local.due_date = evaluate("duedate_#idx#")>
							<cfset local.priority = evaluate("priority_#idx#")>
							<cfif isdefined("status_#idx#")>
								<cfset local.status_task = evaluate("status_#idx#")>
								<cfset local.completion_date = evaluate("completiondate_#idx#")>
								
								<cfif len(trim(task_desc)) eq 0>
									<script>
										alert("#SFLANG1#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif len(trim(start_date)) eq 0>
									<script>
										alert("#SFLANG2#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif not isdate(start_date)>
									<script>
										alert("#SFLANG3#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif len(trim(due_date)) eq 0>
									<script>
										alert("#SFLANG4#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif not isdate(due_date)>
									<script>
										alert("#SFLANG5#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif len(trim(completion_date)) and not isdate(completion_date)>
									<script>
										alert("#SFLANG6#");
										maskButton(false);
									</script>
									<CF_SFABORT>
								<cfelseif (status_task eq 2 or status_task eq 3) and len(trim(completion_date)) eq 0>
									<script>
										maskButton(false);
									</script>
									<CF_SFABORT>
								</cfif>
								
								<cfif evaluate("task_code_#idx#") neq "---"> <!--- update data yang lama --->
									<cfquery name="local.qUpdate" datasource="#request.sdsn#">
										UPDATE TPMDTASK
										SET task_desc = <cfqueryparam value="#task_desc#" cfsqltype="cf_sql_varchar">
										,priority = <cfqueryparam value="#priority#" cfsqltype="cf_sql_integer">
										,status_task = <cfqueryparam value="#status_task#" cfsqltype="cf_sql_integer">
										,startdate = <cfqueryparam value="#CreateODBCDate(start_date)#" cfsqltype="cf_sql_timestamp">
										,duedate = <cfqueryparam value="#CreateODBCDate(due_date)#" cfsqltype="cf_sql_timestamp">
										<cfif (status_task eq 2 or status_task eq 3) and len(trim(completion_date))>
											,completion_date = <cfqueryparam value="#CreateODBCDate(completion_date)#" cfsqltype="cf_sql_timestamp">
										<cfelse>
											,completion_date = NULL
										</cfif>
										WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
										AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
									</cfquery>
								<cfelse> <!--- insert data baru --->
									<cfset task_code = trim(Application.SFUtil.getCode("PRMTASK",'no','true'))>
									<cfquery name="local.qInsert" datasource="#request.sdsn#">
										INSERT INTO TPMDTASK (task_code, assignee, company_code, task_desc, priority, status, 
										startdate, duedate, created_by, created_date, modified_by, modified_date, created_task, status_task, completion_date)
										VALUES(
										<cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#assignee#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#task_desc#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#priority#" cfsqltype="cf_sql_integer">,
										0,
										<cfqueryparam value="#CreateODBCDate(start_date)#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#CreateODBCDate(due_date)#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
										<cfqueryparam value="#emplogin#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#status_task#" cfsqltype="cf_sql_integer">,
										<cfif (status_task eq 2 or status_task eq 3) and len(trim(completion_date))>
											<cfqueryparam value="#CreateODBCDate(completion_date)#" cfsqltype="cf_sql_timestamp">
										<cfelse>
											NULL
										</cfif>
										)
									</cfquery>
								</cfif>
							</cfif>
						</cfif>
					</cfloop>
				</cftransaction>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Update Performance Task",true)>
				<script>
					alert("#SFLANG#");
					parent.popClose();
					refreshPage();
				</script>
			</cfoutput>	
		</cffunction>
		
		<cffunction name="SaveFeedback">
			<cfoutput>
				<cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("JSFeedback Desc Is Empty",true)>
				<cfset LOCAL.SFLANG2=Application.SFParser.TransMLang("JSDate Is Empty",true)>
				<cfset LOCAL.SFLANG3=Application.SFParser.TransMLang("JSDate Is Not In Date Format",true)>
				
				<cftransaction>
					<cfloop from="1" to="#hdn_totalrow#" index="local.idx">
						<cfif isdefined("feedback_code_#idx#")>
							<cfset local.feedback_code = evaluate("feedback_code_#idx#")>
							<cfset local.feedback_desc = evaluate("feedback_desc_#idx#")>
							<cfset local.created_date = evaluate("createddate_#idx#")>
							<cfset local.feedback_type = evaluate("feedback_type_#idx#")>
							<cfset local.severity_level = evaluate("severity_level_#idx#")>
							
							<cfif len(trim(feedback_desc)) eq 0>
								<script>
									alert("#SFLANG1#");
									maskButton(false);
								</script>
								<CF_SFABORT>
							<cfelseif len(trim(created_date)) eq 0>
								<script>
									alert("#SFLANG2#");
									maskButton(false);
								</script>
								<CF_SFABORT>
							<cfelseif not isdate(created_date)>
								<script>
									alert("#SFLANG3#");
									maskButton(false);
								</script>
								<CF_SFABORT>
							</cfif>
							
							<cfif feedback_code neq "---"> <!--- update data yang lama --->
								<cfquery name="local.qUpdate" datasource="#request.sdsn#">
									UPDATE TPMDFEEDBACK
									SET feedback_desc = <cfqueryparam value="#feedback_desc#" cfsqltype="cf_sql_varchar">
									,feedback_type = <cfqueryparam value="#feedback_type#" cfsqltype="cf_sql_varchar">
									,severity_level = <cfqueryparam value="#severity_level#" cfsqltype="cf_sql_integer">
									,created_date = <cfqueryparam value="#created_date#" cfsqltype="cf_sql_timestamp">
									,modified_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
									WHERE feedback_code = <cfqueryparam value="#feedback_code#" cfsqltype="cf_sql_varchar">
									AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
								</cfquery>
							<cfelse> <!--- insert data baru --->
								<cfset feedback_code = trim(Application.SFUtil.getCode("PRMFEEDBACK",'no','true'))>
								<cfquery name="local.qInsert" datasource="#request.sdsn#">
									INSERT INTO TPMDFEEDBACK (feedback_code, feedback_for, company_code, feedback_type,
									feedback_desc, severity_level, status, created_by, created_date, modified_by, modified_date, created_feedback)
									VALUES(
									<cfqueryparam value="#feedback_code#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#assignee#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#feedback_type#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#feedback_desc#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#severity_level#" cfsqltype="cf_sql_integer">,
									0,
									<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#created_date#" cfsqltype="cf_sql_timestamp">,
									<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
									<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
									<cfqueryparam value="#emplogin#" cfsqltype="cf_sql_varchar">
									)
								</cfquery>
							</cfif>
						</cfif>
					</cfloop>
				</cftransaction>
				<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Update Performance Feedback",true)>
				<script>
					alert("#SFLANG#");
					parent.popClose();
					refreshPage();
				</script>
			</cfoutput>	
		</cffunction>
		
		<cffunction name="saveNotes">
			<cfparam name="emplogin" default="">
			<cfparam name="assigner" default="">
			<cfparam name="assignee" default="">
			<cfparam name="task_code" default="">
			<cfparam name="hdnFlag" default="">
			
			<cfoutput>
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSCompletion Date Is Empty",true)>
			
			<cftransaction>
			<cfif hdnFlag eq 2>			
				<cfif empStatus eq 2 and len(trim(EmpCompletionDate)) eq 0>
					<script>
						alert("#SFLANG#");
						maskButton(false);
					</script>
					<CF_SFABORT>
				</cfif>
				
				<cfquery name="local.qUpdate" datasource="#request.sdsn#">
					UPDATE TPMDTASK
					SET status_task = <cfqueryparam value="#empStatus#" cfsqltype="cf_sql_varchar">,
					<cfif empStatus eq 2 and len(trim(EmpCompletionDate)) and isdate(EmpCompletionDate)>
						completion_date = <cfqueryparam value="#EmpCompletionDate#" cfsqltype="cf_sql_timestamp">
					<cfelse>
						completion_date = NULL
					</cfif>
					WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				</cfquery>
			<cfelse>
				<cfif status_task eq 2 and len(trim(completiondate)) eq 0>
					<script>
						alert("#SFLANG#");
						maskButton(false);
					</script>
					<CF_SFABORT>
				</cfif>
				
				<cfquery name="local.qUpdate" datasource="#request.sdsn#">
					UPDATE TPMDTASK
					SET priority = <cfqueryparam value="#priority#" cfsqltype="cf_sql_varchar">,
						status_task = <cfqueryparam value="#status_task#" cfsqltype="cf_sql_varchar">,
					<cfif (status_task eq 2 or status_task eq 3) and len(trim(completiondate)) and isdate(completiondate)>
						completion_date = <cfqueryparam value="#completiondate#" cfsqltype="cf_sql_timestamp">
					<cfelse>
						completion_date = NULL
					</cfif>
					<cfif emplogin eq assigner and isdefined("startdate") and isdate(startdate)>
						,startdate = <cfqueryparam value="#startdate#" cfsqltype="cf_sql_timestamp">
					</cfif>
					<cfif emplogin eq assigner and isdefined("duedate") and isdate(duedate)>
						,duedate = <cfqueryparam value="#duedate#" cfsqltype="cf_sql_timestamp">
					</cfif>
					WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
				</cfquery>
			</cfif>
			
			<cfif isdefined("task_note") and len(trim(task_note))>
				<cfquery name="local.qOrder" datasource="#request.sdsn#">
					SELECT max(note_order) maxorder FROM TPMDTASKNOTES
					WHERE task_code = <cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">
				</cfquery>
				
				<cfset local.order_no = val(qOrder.maxorder) + 1>
				<cfquery name="local.qInsert" datasource="#request.sdsn#">
					INSERT INTO TPMDTASKNOTES  (task_code,company_code,note_order,task_note,created_by,created_date,modified_by,modified_date)  
					VALUES(
						<cfqueryparam value="#task_code#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#order_no#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#task_note#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
						<cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
					)
				</cfquery>	
			</cfif>	
			</cftransaction>
			
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Update Detail Performance Task",true)>
				<script>
					alert("#SFLANG#");
					parent.popClose();
					refreshPage();
				</script>
			</cfoutput>			
		</cffunction>

	    <!--- tambahan yan --->
      <cffunction name="getLibComparison">
	        <cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="reviewer" default="">
	        <cfargument name="libtype" default="">
	        <cfargument name="libcode" default="">
	        <cfargument name="refdate" default="">
	        
	        <cfquery name="Local.qData" datasource="#request.sdsn#">
	        	SELECT DISTINCT C.full_name AS empname, D.pos_name_en AS emppos, E.grade_name AS empgrade, A.achievement, A.score, H.reviewee_empid, B.emp_no AS empno 
	           	<cfif ucase(libtype) eq "APPRAISAL">
		            , LIB.appraisal_name_#request.scookie.lang# AS lib_name
	           	<cfelseif listfindnocase("PERSKPI,ORGKPI",ucase(libtype))>
	               	, LIB.kpi_name_#request.scookie.lang# AS lib_name
	           	<cfelseif ucase(libtype) eq "COMPETENCY">
	               	, LIB.competence_name_#request.scookie.lang# AS lib_name
	            </cfif>
				FROM TPMDPERFORMANCE_EVALD A 

	           	<cfif ucase(libtype) eq "APPRAISAL">
				LEFT JOIN TPMDPERIODAPPRLIB LIB 
					ON LIB.apprlib_code = A.lib_code 
	           	<cfelseif listfindnocase("PERSKPI,ORGKPI",ucase(libtype))>
	            LEFT JOIN TPMDPERIODKPILIB LIB 
	            	ON LIB.kpilib_code = A.lib_code
	           	<cfelseif ucase(libtype) eq "COMPETENCY">
	            LEFT JOIN TPMMCOMPETENCE LIB 
	            	ON LIB.competence_code = A.lib_code
	            </cfif>
	           	<cfif listfindnocase("PERSKPI,ORGKPI,APPRAISAL",ucase(libtype))>
					AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					<!--- AND LIB.reference_date = <cfqueryparam value="#refdate#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
					AND LIB.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            </cfif>
				INNER JOIN TPMDPERFORMANCE_EVALH H 
					ON H.form_no = A.form_no 
					AND H.company_code = A.company_code 
					AND H.reviewer_empid = A.reviewer_empid
	                AND H.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
					<!--- nilainya ambil langsung dari form pake js--->
	                AND H.reviewee_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					AND H.reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">

				LEFT JOIN TEODEMPCOMPANY B 
	            	ON B.emp_id = H.reviewee_empid AND B.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMEMPPERSONAL C 
	            	ON C.emp_id = B.emp_id
				LEFT JOIN TEOMPOSITION D 
	            	ON D.position_id = B.position_id 
	            	AND D.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMJOBGRADE E 
	            	ON E.grade_code = B.grade_code 
	                AND E.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE A.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND A.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
				ORDER BY A.score DESC

	        	<!---SELECT C.full_name AS empname, D.pos_name_#request.scookie.lang# AS emppos, E.grade_name AS empgrade, A.achievement, H.reviewee_empid, B.emp_no AS empno
	           	<cfif ucase(libtype) eq "APPRAISAL">
	               	, LIB.appraisal_name AS lib_name
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	               	, LIB.objective_name AS lib_name
	           	<cfelseif ucase(libtype) eq "COMPETENCY">
	               	, LIB.competency_name AS lib_name
	            </cfif>
				FROM TPMDCPMLIBDETAIL A
	           	<cfif ucase(libtype) eq "APPRAISAL">
	            LEFT JOIN TPMDPERIODAPPLIB LIB ON LIB.appraisal_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "OBJECTIVE">
	            LEFT JOIN TPMDPERIODOBJLIB LIB ON LIB.objective_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	           	<cfelseif ucase(libtype) eq "COMPETENCY">
	            LEFT JOIN TPMDPERIODCOMPLIB LIB ON LIB.competence_code = A.lib_code
	            	AND LIB.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	            </cfif>
	            INNER JOIN TPMDCPMH 
	            	H ON H.request_no = A.request_no 
	                AND H.company_code = A.company_code
	                AND H.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	                
					<!--- nilainya ambil langsung dari form pake js--->
	                AND H.reviewee_empid <> <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	                
				LEFT JOIN TEODEMPCOMPANY B 
	            	ON B.emp_id = H.reviewee_empid AND B.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMEMPPERSONAL C 
	            	ON C.emp_id = B.emp_id
				LEFT JOIN TEOMPOSITION D 
	            	ON D.position_id = B.position_id 
	            	AND D.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				LEFT JOIN TEOMJOBGRADE E 
	            	ON E.grade_code = B.grade_code 
	                AND E.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
				WHERE A.lib_type = <cfqueryparam value="#libtype#" cfsqltype="cf_sql_varchar">
					AND A.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
	            ORDER BY A.achievement DESC--->
	        </cfquery>
			
	        <cfreturn qData>
	    </cffunction>
	    
        <cffunction name="getEmpFormData">
	    	<cfargument name="empid" default="">
	        <cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="compcode" default="">
	        <cfargument name="reqno" default="">
	        <cfargument name="formno" default="">
	        <cfargument name="reviewerempid" default="">
	        <cfargument name="lastreviewer" default="">
			<!---start : ENC51115-79853--->
			<cfargument name="varcoid" required="No" default="#request.scookie.coid#"> 
			<cfargument name="varcocode" required="No" default="#request.scookie.cocode#">
			 <!---end : ENC51115-79853--->
	        <!--- bakalan ada kasus kalo pindah posisi (SOLUSI : harusnya dipassing atau ?)--->
	        <cfquery name="Local.qGetEmpAttr" datasource="#request.sdsn#">
	        	SELECT DISTINCT EC.position_id AS posid, POS.dept_id AS deptid, POS.jobtitle_code AS jtcode
				FROM TEODEMPCOMPANY EC
	            LEFT JOIN TEOMPOSITION POS 
	            	ON POS.position_id = EC.position_id 
		            AND POS.company_id = EC.company_id
				WHERE EC.emp_id = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
					AND EC.company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
	        </cfquery>
	        <cfif ucase(compcode) eq "ORGKPI">
		        <cfset local.empposid = qGetEmpAttr.deptid>
	        <cfelse>
		        <cfset local.empposid = qGetEmpAttr.posid>
	        </cfif>
	        
	        <!--- Task: BUG50615-45605 --->
	        <cfif len(empposid) eq 0>
	            <cfset empposid = -1>
	        </cfif>
	        
	        <cfset local.showFromLastReviewer = 0>
	        <!--- cek kalo udah pernah kesimpan belum (untuk kasus, tabnya ga dibuka terlebih dahulu --->
	        <cfset local.lstLibCode = "">
			
	        <cfif listfindnocase("COMPETENCY,PERSKPI,ORGKPI,APPRAISAL",ucase(compcode))>
		        <cfquery name="Local.qCekData" datasource="#request.sdsn#">
	    	    	SELECT DISTINCT D.lib_code
					FROM TPMDPERFORMANCE_EVALH H
					INNER JOIN TPMDPERFORMANCE_EVALD D 
						ON D.form_no = H.form_no
						AND D.reviewer_empid = H.reviewer_empid
						AND D.lib_type = <cfqueryparam value="#ucase(arguments.compcode)#" cfsqltype="cf_sql_varchar"> 
					WHERE H.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
						AND H.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">

                        <!---
						<cfif REQUEST.DBDRIVER EQ 'ORACLE'>
							AND H.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
						<cfelse>
							AND H.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
						</cfif>
						--remove join or where reference_date --->

						AND H.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND H.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						AND H.reviewer_empid = <cfqueryparam value="#reviewerempid#" cfsqltype="cf_sql_varchar">
		        </cfquery>
	            <cfif not qCekData.recordcount>
			        <cfquery name="Local.qCekData" datasource="#request.sdsn#">
		    	    	SELECT DISTINCT D.lib_code
						FROM TPMDPERFORMANCE_EVALH H
						INNER JOIN TPMDPERFORMANCE_EVALD D 
							ON D.form_no = H.form_no
							AND D.reviewer_empid = H.reviewer_empid
							AND D.lib_type = <cfqueryparam value="#ucase(arguments.compcode)#" cfsqltype="cf_sql_varchar"> 
						WHERE H.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
							AND H.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
							<!--- AND H.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
							AND H.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
							AND H.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
							AND H.reviewer_empid = <cfqueryparam value="#lastreviewer#" cfsqltype="cf_sql_varchar">
			        </cfquery>
		            <cfset showFromLastReviewer = 1>
	            </cfif>
	            <cfif listlen(arguments.reviewerempid)>
	            </cfif>
	            <cfset lstLibCode = valuelist(qCekData.lib_code)>
	            <cfset local.records = qCekData.recordcount>
			 
	        </cfif>
	       
	        <cfif ucase(compcode) eq "COMPETENCY">
	            <cfif request.dbdriver eq "MSSQL">
	            <cfquery name="Local.qGetCompDefault" datasource="#request.sdsn#">
	            	WITH CompLibHier (competence_code,parent_code)
					AS (
						SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN TPMRJOBTITLECOMPETENCE B
							ON B.competence_code = A.competence_code
	                        <cfif len(arguments.reqno) and records>
							AND B.competence_code IN (<cfqueryparam value="#lstLibCode#" list="yes" cfsqltype="cf_sql_varchar">)
	                        <cfelse>
							AND B.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                        </cfif>
						UNION ALL
			
						SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN CompLibHier B ON A.competence_code = B.parent_code
					)
					SELECT DISTINCT Z.competence_code AS libcode, Z.parent_code AS pcode, C.competence_name_#request.scookie.lang# AS libname, 
						C.competence_depth AS depth, C.iscategory, 

		                <cfif len(arguments.reqno) and records>
		                    '' maxpoint,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                    <cfelse>
		                    C.maxpoint, D.point_value AS target,
							'' achievement,
	       	                '' score,
	       	                CASE WHEN PC.weight IS NOT NULL THEN PC.weight WHEN C.weight IS NOT NULL THEN C.weight ELSE '0' END weight,
					   		'0' weightedscore,
	                        '#request.scookie.user.empid#' reviewer_empid,
	                    </cfif>

						'' achscoretype,
				   		'' lookupscoretype,
				   		'N' weightedit,
				   		'N' targetedit

					FROM CompLibHier Z
	                <cfif len(arguments.reqno) and records>
	                LEFT JOIN TPMDPERFORMANCE_EVALH EH
				   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
						AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERFORMANCE_EVALD ED
						ON ED.form_no = EH.form_no
						AND ED.company_code = EH.company_code
						AND ED.lib_code = Z.competence_code
						AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                    <cfif len(arguments.reviewerempid)>
	                    	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
		                    <cfelse>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
		                    </cfif>
	                    </cfif>
	                    
	                </cfif>

					LEFT JOIN TPMMCOMPETENCE C
						ON C.competence_code = Z.competence_code
					LEFT JOIN TPMRJOBTITLECOMPETENCE D
						ON D.competence_code = Z.competence_code
						AND D.competence_code = C.competence_code
						AND D.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERIODCOMPETENCE PC 
	                	ON PC.competence_code = C.competence_code 
	                	AND PC.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                	AND PC.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	                ORDER BY C.competence_depth, libname
	            </cfquery>
	            <cfelse> <!---riz--->
	            <cfquery name="Local.qGetCompDefault" datasource="#request.sdsn#">
	            	
					SELECT DISTINCT Z.competence_code AS libcode, Z.parent_code AS pcode, C.competence_name_#request.scookie.lang# AS libname, 
						C.competence_depth AS depth, C.iscategory, 

		                <cfif len(arguments.reqno) and records>
		                    '' maxpoint,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                    <cfelse>
		                    C.maxpoint, D.point_value AS target,
							'' achievement,
	       	                '' score,
	       	                <cfif request.dbdriver EQ 'ORACLE'>
	       	                	CASE WHEN TO_CHAR(TO_NUMBER(PC.weight)) IS NOT NULL THEN TO_CHAR(TO_NUMBER(PC.weight)) WHEN TO_CHAR(TO_NUMBER(C.weight)) IS NOT NULL THEN TO_CHAR(TO_NUMBER(C.weight)) ELSE '0' END weight,
	       	                <cfelse>
	       	                	CASE WHEN PC.weight IS NOT NULL THEN PC.weight WHEN C.weight IS NOT NULL THEN C.weight ELSE '0' END weight,
	       	                </cfif>
					   		'0' weightedscore,
	                        '#request.scookie.user.empid#' reviewer_empid,
	                    </cfif>

						'' achscoretype,
				   		'' lookupscoretype,
				   		'N' weightedit,
				   		'N' targetedit

					FROM (
					    SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN TPMRJOBTITLECOMPETENCE B
							ON B.competence_code = A.competence_code
	                        <cfif len(arguments.reqno) and records>
							AND B.competence_code IN (<cfqueryparam value="#lstLibCode#" list="yes" cfsqltype="cf_sql_varchar">)
	                        <cfelse>
							AND B.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                        </cfif>
		
						UNION ALL
			
						SELECT A.competence_code, A.parent_code
						FROM TPMMCOMPETENCE A
						INNER JOIN (
						    SELECT A.competence_code, A.parent_code
						    FROM TPMMCOMPETENCE A
						    INNER JOIN TPMRJOBTITLECOMPETENCE B
							ON B.competence_code = A.competence_code
	                        <cfif len(arguments.reqno) and records>
							AND B.competence_code IN (<cfqueryparam value="#lstLibCode#" list="yes" cfsqltype="cf_sql_varchar">)
	                        <cfelse>
							AND B.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                        </cfif>
						) B ON A.competence_code = B.parent_code
					) Z
	                <cfif len(arguments.reqno) and records>
	                LEFT JOIN TPMDPERFORMANCE_EVALH EH
				   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
						AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERFORMANCE_EVALD ED
						ON ED.form_no = EH.form_no
						AND ED.company_code = EH.company_code
						AND ED.lib_code = Z.competence_code
						AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                    <cfif len(arguments.reviewerempid)>
	                    	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
		                    <cfelse>
			                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
		                    </cfif>
	                    </cfif>
	                    
	                </cfif>

					LEFT JOIN TPMMCOMPETENCE C
						ON C.competence_code = Z.competence_code
					LEFT JOIN TPMRJOBTITLECOMPETENCE D
						ON D.competence_code = Z.competence_code
						AND D.competence_code = C.competence_code
						AND D.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
					LEFT JOIN TPMDPERIODCOMPETENCE PC 
	                	ON PC.competence_code = C.competence_code 
	                	AND PC.jobtitle_code = <cfqueryparam value="#qGetEmpAttr.jtcode#" cfsqltype="cf_sql_varchar">
	                	AND PC.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	                ORDER BY C.competence_depth,libname
	            </cfquery>
	            </cfif>
	            <!---<cfoutput><div style="display:none"><cfdump var="#qGetCompDefault#"></div></cfoutput>
	            <cf_sfwritelog dump="qGetCompDefault" prefix="YAN_">--->
	            <!---<cf_sfwritelog dump="qGetCompDefault" folder="GD_EVAL" prefix="qGetCompDefault_deb_">--->
	            <cfreturn qGetCompDefault>
	        
	        <cfelseif listfindnocase("ORGKPI",ucase(compcode))>
	        	<cfquery name="local.qCekFromPlanOrEval" datasource="#request.sdsn#">
	            	SELECT lib_code FROM TPMDPERFORMANCE_EVALKPI
	            	WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	                    AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	                    AND orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">
	            </cfquery>
				 
				
	            <cfif len(arguments.reqno) and records>
	            
	                <cfquery name="Local.qGetOrgUnit" datasource="#request.sdsn#">
	                    SELECT DISTINCT ED.lib_name_#request.scookie.lang# AS libname, 
	                    	EVKPI.lib_desc_#request.scookie.lang# lib_desc_en,
	    			        ED.lib_code AS libcode, ED.parent_code AS pcode, ED.lib_depth AS depth, ED.iscategory,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                        ED.achievement_type AS achscoretype,
	    			   		ED.lookup_code AS lookupscoretype,
	    			   		EVKPI.lib_order,
	                        <cfif not qCekFromPlanOrEval.recordcount>
	                            '0' evalkpi_status
	                        <cfelse>
	                            EVKPI.evalkpi_status
	                        </cfif>
	                    <cfif not qCekFromPlanOrEval.recordcount>
	    				FROM TPMDPERFORMANCE_PLANKPI EVKPI
	                    <cfelse>
	    				FROM TPMDPERFORMANCE_EVALKPI EVKPI
	                    </cfif>
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.lib_code = EVKPI.lib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reqno) and records>
	    					AND ED.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	                        </cfif>

	                        <cfif len(arguments.reviewerempid)>
	    	                    <cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	    				WHERE EVKPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">
	    				ORDER BY EVKPI.lib_order, ED.lib_depth, ED.lib_name_#request.scookie.lang#
	                </cfquery>
	                
	            <cfelse>
	            
	    	        <cfquery name="Local.qGetOrgUnit" datasource="#request.sdsn#">
	    				SELECT distinct EVKPI.lib_code AS libcode, EVKPI.parent_code AS pcode, EVKPI.lib_name_#request.scookie.lang# AS libname, 
	    				EVKPI.lib_desc_#request.scookie.lang# lib_desc_en,
	    					EVKPI.lib_depth AS depth, EVKPI.iscategory,  
	    					<cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						Round(ED.weight,#REQUEST.InitVarCountDeC#) weight,
	    						Round(ED.weightedscore,#REQUEST.InitVarCountDeC#) weightedscore,
	                            ED.reviewer_empid,
	                        <cfelseif not qCekFromPlanOrEval.recordcount>
	    		                EVKPI.target,
	                            '' achievement,
	    		                '0' score,
	    		                Round(EVKPI.weight,#REQUEST.InitVarCountDeC#) weight,
	    		                '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                        <cfelse>
	    		                EVKPI.target,
	                            EVKPI.achievement,
	    		                EVKPI.score,
	    		                Round(EVKPI.weight,#REQUEST.InitVarCountDeC#) weight,
	    		                '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                        </cfif>
	    
	    					<!---EVKPI.achievement_type AS achscoretype, --->
							<cfif not qCekFromPlanOrEval.recordcount>
							CASE WHEN EVKPI.isnew = 'Y' THEN EVKPI.achievement_type 
								WHEN EVKPI.isnew = 'N' THEN LIB.achievement_type 
								END achscoretype,
							<cfelse>
							CASE 
									WHEN EVKPI.achievement_type IS NOT NULL AND <cfif request.dbdriver eq "MSSQL">LEN(EVKPI.achievement_type)<cfelse>LENGTH(EVKPI.achievement_type)</cfif> <> 0 THEN EVKPI.achievement_type
									WHEN PK.achievement_type IS NOT NULL THEN PK.achievement_type
									ELSE LIB.achievement_type
								END achscoretype,
							</cfif>
	                        CASE
	                        	WHEN EVKPI.lookup_code IS NOT NULL THEN EVKPI.lookup_code <!--- TCK1507-002557 --->
	                        	WHEN PK.lookup_code IS NOT NULL THEN PK.lookup_code
	                        	ELSE ''
	                        END lookupscoretype,
	                        
	    			   		'N' weightedit,
	    			   		'N' targetedit,
	    			   		
	    			   		EVKPI.lib_order,
	                        
	                    <cfif not qCekFromPlanOrEval.recordcount>
	                        '0' evalkpi_status
	                    <cfelse>
	                        EVKPI.evalkpi_status
	                    </cfif>
	    
	                    <cfif not qCekFromPlanOrEval.recordcount>
	    				FROM TPMDPERFORMANCE_PLANKPI EVKPI
	                    <cfelse>
	    				FROM TPMDPERFORMANCE_EVALKPI EVKPI
	                    </cfif>
	                    
	                    <cfif len(arguments.reqno) and records>
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.lib_code = EVKPI.lib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        
	                        <cfif len(arguments.reqno) and records>
	    					AND ED.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	                        </cfif>
	                        
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                    
	                    LEFT JOIN TPMDPERIODKPI PK
	    					ON PK.period_code = EVKPI.period_code 
	    					<!--- AND PK.reference_date = EVKPI.reference_date --remove join or where reference_date --->
	    					AND PK.company_code = EVKPI.company_code
	    					AND PK.position_id = EVKPI.orgunit_id
	    					AND PK.kpilib_code = EVKPI.lib_code
	    					AND PK.kpi_type = 'ORGUNIT'
	    				LEFT JOIN TPMDPERIODKPILIB LIB
	    					ON LIB.period_code = EVKPI.period_code
	    					AND LIB.company_code = EVKPI.company_code
	    					AND LIB.kpilib_code = EVKPI.lib_code
	    					<!--- AND LIB.reference_date = EVKPI.reference_date --remove join or where reference_date --->
	    
	    				WHERE EVKPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND EVKPI.orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">
	    					<cfif not qCekFromPlanOrEval.recordcount>
	                        AND EVKPI.request_no = (
	                            SELECT <cfif request.dbdriver EQ "MSSQL">TOP 1</cfif> request_no 
	                            FROM TPMDPERFORMANCE_PLANKPI 
	                            WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar"> 
	                                AND orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer"> 
	                                AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	                            ORDER BY modified_date DESC <cfif request.dbdriver EQ "MYSQL">LIMIT 1</cfif>  
	                        )
	                        </cfif>
	                    ORDER BY EVKPI.lib_order, EVKPI.lib_depth, EVKPI.lib_name_#request.scookie.lang#
	    	        </cfquery>
					
	    	        <cfif not qGetOrgUnit.recordcount>
	    		        <cfquery name="Local.qGetOrgUnit" datasource="#request.sdsn#">
	    		        	SELECT PLKPI.lib_code AS libcode, PLKPI.lib_order,PLKPI.parent_code AS pcode, PLKPI.lib_name_#request.scookie.lang# AS libname, PLKPI.lib_desc_en, 
	    						PLKPI.lib_depth AS depth, PLKPI.iscategory, 
	    						PLKPI.achievement_type AS achscoretype, PLKPI.weight, PLKPI.target, PLKPI.isnew, '' evalkpi_status,
	                            '' achievement, 
	                            PLKPI.lookup_code lookupscoretype, <!--- TCK1507-002557 --->
	                            '' score, '0' weightedscore
	    					FROM TPMDPERFORMANCE_PLANKPI PLKPI
	    					INNER JOIN TCLTREQUEST R 
	    						ON R.req_no = PLKPI.request_no
	    						AND R.req_type = 'PERFORMANCE.PLAN'
	    						AND R.company_code = PLKPI.company_code
	    						AND R.status IN (3,9)
	    					WHERE PLKPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						<!--- AND PLKPI.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp"> --remove join or where reference_date --->
	    						AND PLKPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PLKPI.orgunit_id = <cfqueryparam value="#qGetEmpAttr.deptid#" cfsqltype="cf_sql_integer">
	    		               
								<!---start : ENC50915-79511--->
								AND PLKPI.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
								<!---end : ENC50915-79511--->
	    	                ORDER BY PLKPI.lib_order, PLKPI.lib_depth, PLKPI.lib_name_#request.scookie.lang#
	    		        </cfquery>
						
	    	        </cfif>
		        
		        </cfif>
		        
			    <cfreturn qGetOrgUnit>
	            
	        <cfelseif listfindnocase("PERSKPI",ucase(compcode))>

	        	<!--- cek kalo ada di PLAND --->
	            <cfquery name="Local.qGetFromPlan" datasource="#request.sdsn#">
	            	SELECT DISTINCT form_no, reviewer_empid, request_no,created_date FROM TPMDPERFORMANCE_PLANH
	                WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	   	            	AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	           	        AND reviewee_empid = <cfqueryparam value="#arguments.empid#" cfsqltype="cf_sql_varchar">
	               	    AND isfinal = 1
	               	    AND head_status = 1
	               	order by created_date desc
	       	            <!--- AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp"> --->
	            </cfquery>
	            
	            <!--- <cfquery name="Local.qCekLib" datasource="#request.sdsn#">
	            	SELECT * FROM TPMDPERFORMANCE_PLAND
	                WHERE form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                	AND reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	            </cfquery> ---->
	            
	            <cfquery name="Local.qGetNewLib" datasource="#request.sdsn#">
	            	SELECT DISTINCT lib_code FROM TPMDPERFORMANCE_PLAND
	                WHERE form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                	AND reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	                    AND isnew = 'Y'
	            </cfquery>
	           
	            <cfset Local.lstNewLibCode = valuelist(qGetNewLib.lib_code)>
	            
	            <cfif (len(arguments.reqno) and records)> <!---OR (not qCekLib.recordcount) BUG50915-51061--->
	          
	            	<cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	            	    SELECT * from (
	            	    SELECT DISTINCT ED.lib_name_#request.scookie.lang# AS libname,
	            	        <!--- AP.kpi_desc_#request.scookie.lang# AS lib_desc_en, --->
	            	        ED.lib_desc_#request.scookie.lang# AS lib_desc_en, 
	            	        
	    			        ED.lib_code AS libcode, ED.parent_code AS pcode, ED.lib_depth AS depth, ED.iscategory,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                        ED.achievement_type AS achscoretype,
	                            <cfif qGetFromPlan.recordcount>
	                            PLD.lib_order,
	                            <cfelse>
	                            '0' lib_order,
	                            </cfif>
	    			   		ED.lookup_code AS lookupscoretype
	                        <!---
	    			   		, PA.editable_weight AS weightedit
	    			   		, PA.editable_target AS targetedit
	    			   		--->
	                    FROM TPMDPERFORMANCE_EVALH EH
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	    			    LEFT JOIN TPMDPERIODKPILIB AP 
		                    ON ED.lib_code = AP.kpilib_code AND EH.period_code=AP.period_code 
		                    AND ED.company_code =  AP.company_code
	                    <cfif qGetFromPlan.recordcount>
	    	            LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	                        ON PLD.lib_code = ED.lib_code
	                        AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                        AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							AND PLD.request_no = <cfqueryparam value="#qGetFromPlan.request_no#" cfsqltype="cf_sql_varchar">
	                    </cfif>

	                    WHERE 
	                        <cfif len(arguments.reviewerempid)>
	    	                    <cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                     ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                     ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>

	                        AND EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				) tblperskpi
	    				ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	            	</cfquery>
	            	
	            <cfelse>
	                
					
					
					<cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	            	   SELECT * from (
	            	    SELECT DISTINCT PLD.lib_name_#request.scookie.lang# AS libname, 
	    			        PLD.lib_code AS libcode, PLD.parent_code AS pcode, PLD.lib_depth AS depth, PLD.iscategory,
			                PLD.target,
							'' achievement,
							'' score,
							PLD.weight,
							'' weightedscore,
	                        '' reviewer_empid,
	                        PLD.achievement_type AS achscoretype,
	                            PLD.lib_order,
	    			   		PLD.lookup_code AS lookupscoretype,
	    			   		<!--- AP.kpi_desc_#request.scookie.lang# AS lib_desc_en --->
	    			   		PLD.lib_desc_#request.scookie.lang# AS lib_desc_en
	                       
	                    FROM TPMDPERFORMANCE_PLANH PLANH
	    				  LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	    				  
	                        ON (PLD.lib_code = PLD.lib_code
							 <cfif qGetFromPlan.recordcount> 
							 AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
							 AND PLD.request_no = <cfqueryparam value="#qGetFromPlan.request_no#" cfsqltype="cf_sql_varchar">
							 AND PLD.reviewer_empid  = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							 <cfelse>
							AND 1 = 0
							 </cfif>
	                        )
	                        LEFT JOIN TPMDPERIODKPILIB AP 
		                    ON PLD.lib_code = AP.kpilib_code AND PLANH.period_code=AP.period_code 
		                    AND PLD.company_code =  AP.company_code
	                        WHERE PLANH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND PLANH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
							<cfif qGetFromPlan.recordcount> 
								AND PLANH.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
								AND PLANH.request_no = <cfqueryparam value="#qGetFromPlan.request_no#" cfsqltype="cf_sql_varchar">
								AND PLANH.REVIEWER_EMPID = <cfqueryparam value="#qGetFromPlan.REVIEWER_EMPID#" cfsqltype="cf_sql_varchar">
							<cfelse>
								AND 1 = 0
							</cfif>
							
							
	    				) tblperskpi
	    				ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	    				
	    				
	            	</cfquery>
					
					
					
					<!---<cf_sfwritelog dump="arguments.lastreviewer,arguments.reviewerempid,qGetFromPlan.REVIEWER_EMPID" prefix="qGetKPIDefault_"> ---->
					
					<!-----
					
					<cfif request.dbdriver eq "MSSQL">
						  
	            	<cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	                	WITH KPILibHier (kpilib_code,parent_code,kpi_name, depth, iscategory)
	    				AS (
	    					SELECT K.kpilib_code, K.parent_code, K.kpi_name_#request.scookie.lang#, K.kpi_depth, K.iscategory
	    					FROM TPMDPERIODKPILIB K
	    					INNER JOIN TPMDPERIODKPI PK
	    						ON PK.period_code = K.period_code
	    						AND PK.company_code =K.company_code
	    						AND PK.reference_date = K.reference_date
	    						AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    						AND PK.kpilib_code = K.kpilib_code
	    					WHERE PK.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND PK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PK.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                            <cfif ucase(compcode) eq "PERSKPI">
	    	                        AND PK.kpi_type = 'PERSONAL'
	                            <cfelse>
	    	                        AND PK.kpi_type = 'ORGUNIT'
	                            </cfif>
	    	
	    					UNION ALL
	    		
	    					SELECT A.kpilib_code, A.parent_code, A.kpi_name_#request.scookie.lang#, A.kpi_depth, A.iscategory
	    					FROM TPMDPERIODKPILIB A
	    					INNER JOIN KPILibHier AS B ON A.kpilib_code = B.parent_code
	    					<!--- pake yg category juga --->
	    					<!---
	    					WHERE A.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND A.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND A.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				
	    		--->
	    				)	
	    
	                    <cfif qGetNewLib.recordcount>
	                    SELECT * FROM (
	                    </cfif>
	                    
	    				SELECT DISTINCT Z.kpi_name AS libname,z.lib_desc_en, Z.kpilib_code AS libcode, Z.parent_code AS pcode, Z.depth, Z.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            <cfif qGetFromPlan.recordcount>
	                            PLD.lib_order,
	                            <cfelse>
	                            '0' lib_order,
	                            </cfif>
	    	                <cfelseif qGetFromPlan.recordcount>
	                        	PLD.target,
	                            '' achievement,
	           	                '' score,
	                            PLD.weight,
	                            '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        <cfelse>
	    						PK.target,
	    						'' achievement,
	           	                '' score,
	    						CASE 
	                            	<!---
	    							WHEN PK.weight IS NOT NULL AND PK.weight <> 0 THEN PK.weight 
	    							WHEN PK.weight = 0 AND KPI.weight IS NOT NULL AND KPI.weight <> 0 THEN KPI.weight
	    							ELSE PK.weight 
	    							--->
	    							WHEN PK.weight IS NOT NULL THEN PK.weight 
	    							WHEN KPI.weight IS NOT NULL THEN KPI.weight
	    							ELSE '0'
	    						END weight,
	    				   		'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            '0' lib_order,
	                        </cfif>
	    			   		CASE 
	    			   			WHEN PK.achievement_type IS NOT NULL THEN PK.achievement_type
	    			   			ELSE KPI.achievement_type
	    			   		END achscoretype,
	    			
	    			   		PK.lookup_code AS lookupscoretype,
	    			   		PK.editable_weight AS weightedit,
	    			   		PK.editable_target AS targetedit
	       		
	    			   	FROM KPILibHier Z
	                    
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = Z.kpilib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                    
	                    <!--- dipisah, biar yang isnew juga keambil --->
	                    <cfif qGetFromPlan.recordcount>
	    	            LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	                        ON PLD.lib_code = Z.kpilib_code
	                        AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                        AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	    
	    			   	LEFT JOIN TPMDPERIODKPILIB KPI
	    			   		ON KPI.kpilib_code = Z.kpilib_code
	    			   		AND KPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				LEFT JOIN TPMDPERIODKPI PK
	    					ON PK.period_code = KPI.period_code
	    					AND PK.company_code =KPI.company_code
	    					AND PK.reference_date = KPI.reference_date
	    					AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    					AND PK.kpilib_code = KPI.kpilib_code
	                        <cfif ucase(compcode) eq "PERSKPI">
	    	                    AND PK.kpi_type = 'PERSONAL'
	                        <cfelse>
	    	                    AND PK.kpi_type = 'ORGUNIT'
	                        </cfif>
	                        
	                    <cfif not qGetNewLib.recordcount>
	    					ORDER BY Z.depth, Z.kpi_name
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    UNION
	                    
	                    SELECT PLD.lib_name_en AS libname,AP.kpi_desc_#request.scookie.lang# AS lib_desc_en, PLD.lib_code AS libcode, PLD.parent_code AS pcode, PLD.lib_depth AS depth, PLD.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    						ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            PLD.lib_order,
	                    	<cfelse>
	    						PLD.target,
	    						'' achievement,
	    						'' score,
	    						PLD.weight,
	    						'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        </cfif>
	                            PLD.achievement_type achscoretype,
	                            PLD.lookup_code AS lookupscoretype, <!--- TCK1507-002557 --->
	                            <!---
	                            '' lookupscoretype,
	                            --->

	                            'N' weightedit,
	                            'N' targetedit
	                            
	                    FROM TPMDPERFORMANCE_PLAND PLD  
	                    
	    				<!---lstNewLibCode--->
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = PLD.lib_code
	    					
	    			    LEFT JOIN TPMDPERIODKPILIB AP 
		                    ON ED.lib_code = AP.kpilib_code AND EH.period_code=AP.period_code 
		                    AND ED.company_code =  AP.company_code	
	                    </cfif>
	                    
	                    WHERE 
	                        upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif> AND
	                        PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                    	AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	                        AND PLD.isnew = 'Y'
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    ) tblperskpi
	                    ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	                    </cfif>
	                </cfquery>
						
	                <cfelse> <!---riz--->
	                    <cfquery name="Local.qGetKPIDefault" datasource="#request.sdsn#">
	    
	                    <cfif qGetNewLib.recordcount>
	                    SELECT * FROM (
	                    </cfif>
	                    
	    				SELECT DISTINCT Z.kpi_name AS libname,Z.lib_desc_en, Z.kpilib_code AS libcode, Z.parent_code AS pcode, Z.depth, Z.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            <cfif qGetFromPlan.recordcount>
	                            PLD.lib_order,
	                            <cfelse>
	                            '0' lib_order,
	                            </cfif>
	    	                <cfelseif qGetFromPlan.recordcount>
	                        	PLD.target,
	                            '' achievement,
	           	                '' score,
	                            PLD.weight,
	                            '0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        <cfelse>
	    						PK.target,
	    						'' achievement,
	           	                '' score,
	    						CASE 
	                            	<!---
	    							WHEN PK.weight IS NOT NULL AND PK.weight <> 0 THEN PK.weight 
	    							WHEN PK.weight = 0 AND KPI.weight IS NOT NULL AND KPI.weight <> 0 THEN KPI.weight
	    							ELSE PK.weight 
	    							--->
	    							WHEN PK.weight IS NOT NULL THEN PK.weight 
	    							WHEN KPI.weight IS NOT NULL THEN KPI.weight
	    							ELSE '0'
	    						END weight,
	    				   		'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            '0' lib_order,
	                        </cfif>
	    			   		CASE 
	    			   			WHEN PK.achievement_type IS NOT NULL THEN PK.achievement_type
	    			   			ELSE KPI.achievement_type
	    			   		END achscoretype,
	    			
	    			   		PK.lookup_code AS lookupscoretype,
	    			   		PK.editable_weight AS weightedit,
	    			   		PK.editable_target AS targetedit
	       		
	    			   	FROM 
	    			   	(
	    					SELECT K.kpilib_code, K.parent_code,K.kpi_desc_#request.scookie.lang# AS lib_desc_en, K.kpi_name_#request.scookie.lang# kpi_name, K.kpi_depth depth, K.iscategory
	    					FROM TPMDPERIODKPILIB K
	    					INNER JOIN TPMDPERIODKPI PK
	    						ON PK.period_code = K.period_code
	    						AND PK.company_code =K.company_code
	    						AND PK.reference_date = K.reference_date
	    						AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    						AND PK.kpilib_code = K.kpilib_code
	    					WHERE PK.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND PK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PK.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                            <cfif ucase(compcode) eq "PERSKPI">
	    	                        AND PK.kpi_type = 'PERSONAL'
	                            <cfelse>
	    	                        AND PK.kpi_type = 'ORGUNIT'
	                            </cfif>
	    	
	    					UNION ALL
	    		
	    					SELECT A.kpilib_code, A.parent_code,K.kpi_desc_#request.scookie.lang# AS lib_desc_en,A.kpi_name_#request.scookie.lang#, A.kpi_depth, A.iscategory
	    					FROM TPMDPERIODKPILIB A
	    					INNER JOIN (
	    					    SELECT K.kpilib_code, K.parent_code, K.kpi_name_#request.scookie.lang#, K.kpi_depth, K.iscategory
	        					FROM TPMDPERIODKPILIB K
	        					INNER JOIN TPMDPERIODKPI PK
	        						ON PK.period_code = K.period_code
	        						AND PK.company_code =K.company_code
	        						AND PK.reference_date = K.reference_date
	        						AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	        						AND PK.kpilib_code = K.kpilib_code
	        					WHERE PK.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	        						AND PK.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	        						AND PK.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	                                <cfif ucase(compcode) eq "PERSKPI">
	        	                        AND PK.kpi_type = 'PERSONAL'
	                                <cfelse>
	        	                        AND PK.kpi_type = 'ORGUNIT'
	                                </cfif>
	    					) AS B ON A.kpilib_code = B.parent_code
	    					
	    		
	    				) Z
	                    
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = Z.kpilib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                    
	                    <!--- dipisah, biar yang isnew juga keambil --->
	                    <cfif qGetFromPlan.recordcount>
	    	            LEFT JOIN TPMDPERFORMANCE_PLAND PLD
	                        ON PLD.lib_code = Z.kpilib_code
	                        AND PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                        AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	    
	    			   	LEFT JOIN TPMDPERIODKPILIB KPI
	    			   		ON KPI.kpilib_code = Z.kpilib_code
	    			   		AND KPI.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND KPI.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				LEFT JOIN TPMDPERIODKPI PK
	    					ON PK.period_code = KPI.period_code
	    					AND PK.company_code =KPI.company_code
	    					AND PK.reference_date = KPI.reference_date
	    					AND PK.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    					AND PK.kpilib_code = KPI.kpilib_code
	                        <cfif ucase(compcode) eq "PERSKPI">
	    	                    AND PK.kpi_type = 'PERSONAL'
	                        <cfelse>
	    	                    AND PK.kpi_type = 'ORGUNIT'
	                        </cfif>
	                        
	                    <cfif not qGetNewLib.recordcount>
	    					ORDER BY Z.depth, Z.kpi_name
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    UNION
	                    
	                    SELECT PLD.lib_name_en AS libname, PLD.lib_code AS libcode, PLD.parent_code AS pcode, PLD.lib_depth AS depth, PLD.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    						ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                            PLD.lib_order,
	                    	<cfelse>
	    						PLD.target,
	    						'' achievement,
	    						'' score,
	    						PLD.weight,
	    						'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                            PLD.lib_order,
	                        </cfif>
	                            
	                            PLD.achievement_type achscoretype,
	                            PLD.lookup_code AS lookupscoretype, <!--- TCK1507-002557 --->
	                            <!---
	                            '' lookupscoretype,
	                            --->

	                            'N' weightedit,
	                            'N' targetedit
	                            
	                    FROM TPMDPERFORMANCE_PLAND PLD  
	                    
	    				<!---lstNewLibCode--->
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = PLD.lib_code
	    			  	 LEFT JOIN TPMDPERIODKPIRLIB AP 
		                 ON ED.lib_code = AP.kpilib_code AND EH.period_code=AP.period_code 
		                 AND ED.company_code =  AP.company_code
	                    WHERE 
	                       upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
	                        <cfif len(arguments.reviewerempid)>
	                        	<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    <cfelse>
	    		                    AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
	    	                    </cfif>
	                        </cfif>
	                    </cfif>
	                        PLD.form_no = <cfqueryparam value="#qGetFromPlan.form_no#" cfsqltype="cf_sql_varchar">
	                    	AND PLD.reviewer_empid = <cfqueryparam value="#qGetFromPlan.reviewer_empid#" cfsqltype="cf_sql_varchar">
	                        AND PLD.isnew = 'Y'
							AND PLD.request_no in (select request_no from TPMDPERFORMANCE_PLANH where isfinal=1 and form_no = PLD.form_no) <!---added by ENC50915-79511--->
	                    </cfif>
	                    
	                    <cfif qGetNewLib.recordcount>
	                    ) tblperskpi
	                    ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname
	                    </cfif>
	                </cfquery>
	                </cfif> <!---riz--->
					
					---->
	                
	            </cfif>
	         
			    <cfreturn qGetKPIDefault>
			    
	        <cfelseif ucase(compcode) eq "APPRAISAL">
	            <cfif len(arguments.reqno) and records>
	    			<cfquery name="local.qGetApprDefault" datasource="#request.sdsn#">
	    			    SELECT DISTINCT ED.lib_name_#request.scookie.lang# AS libname, AP.appraisal_desc_#request.scookie.lang# as description,
	    			        ED.lib_code AS libcode, ED.parent_code AS pcode, ED.lib_depth AS depth, ED.iscategory,
			                ED.target,
							ED.achievement,
							ED.score,
							ED.weight,
							ED.weightedscore,
	                        ED.reviewer_empid,
	                        ED.achievement_type AS achscoretype,
	    			   		ED.lookup_code AS lookupscoretype,
							AP.order_no
	                        <!---
	    			   		, PA.editable_weight AS weightedit
	    			   		, PA.editable_target AS targetedit
	    			   		--->
	                    FROM TPMDPERFORMANCE_EVALH EH
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    			    LEFT JOIN TPMDPERIODAPPRLIB AP 
		                ON ED.lib_code = AP.apprlib_code AND EH.period_code=AP.period_code 
		                AND ED.company_code =  AP.company_code
	
	    					
	                    WHERE EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
							<cfif varcocode eq request.scookie.cocode>
								<cfif len(arguments.reviewerempid)>
									<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
									<cfelse>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
									</cfif>
								</cfif>
							</cfif>
	    		  	ORDER BY ED.lib_depth, AP.order_no, ED.lib_name_#request.scookie.lang#
	    			</cfquery>
	    	
	            <cfelse>
	                <cfif request.dbdriver eq "MSSQL">
	                <cfquery name="Local.qGetApprDefault" datasource="#request.sdsn#">
	    	           	WITH ApprLibHier (apprlib_code,parent_code,order_no,appraisal_name,description,depth, iscategory)
	    				AS (
	    					SELECT A.apprlib_code, A.parent_code,A.order_no, A.appraisal_name_#request.scookie.lang#,  A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
	    					FROM TPMDPERIODAPPRLIB A
	    					INNER JOIN TPMDPERIODAPPRAISAL PA
	    						ON PA.period_code = A.period_code
	    						AND PA.company_code =A.company_code
	    						AND PA.reference_date = A.reference_date
	    						AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    						AND PA.apprlib_code = A.apprlib_code
	    					WHERE PA.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND PA.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND PA.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    		
	    					UNION ALL
	    					SELECT A.apprlib_code, A.parent_code, A.order_no,A.appraisal_name_#request.scookie.lang#, 
	    					A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
	    					FROM TPMDPERIODAPPRLIB A
	    					INNER JOIN ApprLibHier B ON A.apprlib_code = B.parent_code
	    					WHERE A.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    						AND A.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    						AND A.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				)

	    				SELECT DISTINCT Z.appraisal_name AS libname, z.description,Z.apprlib_code AS libcode, Z.order_no, Z.parent_code AS pcode, Z.depth, Z.iscategory,
	    	                <cfif len(arguments.reqno) and records>
	    		                ED.target,
	    						ED.achievement,
	    						ED.score,
	    						ED.weight,
	    						ED.weightedscore,
	                            ED.reviewer_empid,
	                        <cfelse>
	    						PA.target,
	    						'' achievement,
	           	                '' score,
	    						CASE 
	                            	<!---
	    							WHEN PA.weight IS NOT NULL AND PA.weight <> 0 THEN PA.weight 
	    							WHEN PA.weight = 0 AND APPR.weight IS NOT NULL AND APPR.weight <> 0 THEN APPR.weight
	    							ELSE PA.weight
	    							--->
	    							WHEN PA.weight IS NOT NULL THEN PA.weight 
	    							WHEN APPR.weight IS NOT NULL THEN APPR.weight
	    							ELSE '0'
	    						END weight,
	    				   		'0' weightedscore,
	                            '#request.scookie.user.empid#' reviewer_empid,
	                        </cfif>
	    			   		CASE 
	    			   			WHEN PA.achievement_type IS NOT NULL THEN PA.achievement_type
	    			   			ELSE APPR.achievement_type
	    		   			END achscoretype,
	    			   		PA.lookup_code AS lookupscoretype,
	    
	    			   		PA.editable_weight AS weightedit,
	    			   		PA.editable_target AS targetedit

	    			   	FROM ApprLibHier Z
	                    <cfif len(arguments.reqno) and records>
	                    LEFT JOIN TPMDPERFORMANCE_EVALH EH
	    			   		ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    			   		AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
	    					AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
	    				LEFT JOIN TPMDPERFORMANCE_EVALD ED
	    					ON ED.form_no = EH.form_no
	    					AND ED.company_code = EH.company_code
	    					AND ED.lib_code = Z.apprlib_code
	    					AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
							<cfif varcocode eq request.scookie.cocode>
								<cfif len(arguments.reviewerempid)>
									<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
									<cfelse>
										AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
									</cfif>
								</cfif>
							</cfif>
	                    </cfif>
	            
	    			   	LEFT JOIN TPMDPERIODAPPRLIB APPR
	    			   		ON APPR.apprlib_code = Z.apprlib_code
	                   	    AND APPR.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
	    					AND APPR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	    					AND APPR.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
	    				LEFT JOIN TPMDPERIODAPPRAISAL PA
	    					ON PA.period_code = APPR.period_code
	    					AND PA.company_code =APPR.company_code
	    					AND PA.reference_date = APPR.reference_date
	    					AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
	    					AND PA.apprlib_code = APPR.apprlib_code
	    				
						ORDER BY Z.depth, Z.order_no, Z.appraisal_name
	    			</cfquery>
	    			<cfelse> <!---riz--->
						<cfquery name="Local.qGetApprDefault" datasource="#request.sdsn#">
							SELECT DISTINCT Z.appraisal_name AS libname, z.description,Z.apprlib_code AS libcode, Z.order_no,Z.parent_code AS pcode, Z.depth, Z.iscategory,
								<cfif len(arguments.reqno) and records>
									ED.target,
									ED.achievement,
									ED.score,
									ED.weight,
									ED.weightedscore,
									ED.reviewer_empid,
								<cfelse>
									PA.target,
									'' achievement,
									'' score,
									<cfif request.dbdriver eq 'ORACLE'>
										CASE 
											WHEN PA.weight IS NOT NULL THEN PA.weight
											WHEN APPR.weight IS NOT NULL THEN APPR.weight
											ELSE 0
										END weight,
									<cfelse>
										CASE 
											<!---
											WHEN PA.weight IS NOT NULL AND PA.weight <> 0 THEN PA.weight 
											WHEN PA.weight = 0 AND APPR.weight IS NOT NULL AND APPR.weight <> 0 THEN APPR.weight
											ELSE PA.weight
											--->
											WHEN PA.weight IS NOT NULL THEN PA.weight 
											WHEN APPR.weight IS NOT NULL THEN APPR.weight
											ELSE '0'
										END weight,
									</cfif>
									'0' weightedscore,
									'#request.scookie.user.empid#' reviewer_empid,
								</cfif>
								CASE 
									WHEN PA.achievement_type IS NOT NULL THEN PA.achievement_type
									ELSE APPR.achievement_type
								END achscoretype,
								PA.lookup_code AS lookupscoretype,
			
								PA.editable_weight AS weightedit,
								PA.editable_target AS targetedit

							FROM 
							(
								SELECT A.apprlib_code, A.parent_code, A.order_no, A.appraisal_name_#request.scookie.lang# appraisal_name,
								A.appraisal_desc_#request.scookie.lang# description,A.appraisal_depth depth, A.iscategory
								FROM TPMDPERIODAPPRLIB A
								INNER JOIN TPMDPERIODAPPRAISAL PA
									ON PA.period_code = A.period_code
									AND PA.company_code =A.company_code
									AND PA.reference_date = A.reference_date
									AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
									AND PA.apprlib_code = A.apprlib_code
								WHERE PA.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
									AND PA.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
									AND PA.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					
								UNION ALL
					
								SELECT A.apprlib_code, A.parent_code, A.order_no, A.appraisal_name_#request.scookie.lang# ,
								A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
								FROM TPMDPERIODAPPRLIB A
								INNER JOIN (
									SELECT A.apprlib_code, A.parent_code, A.appraisal_name_#request.scookie.lang#,  A.appraisal_desc_#request.scookie.lang#,A.appraisal_depth, A.iscategory
									FROM TPMDPERIODAPPRLIB A
									INNER JOIN TPMDPERIODAPPRAISAL PA
										ON PA.period_code = A.period_code
										AND PA.company_code =A.company_code
										AND PA.reference_date = A.reference_date
										AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
										AND PA.apprlib_code = A.apprlib_code
									WHERE PA.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
										AND PA.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
										AND PA.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
								) B ON A.apprlib_code = B.parent_code
								WHERE A.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
									AND A.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
									AND A.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
							) Z
							<cfif len(arguments.reqno) and records>
							LEFT JOIN TPMDPERFORMANCE_EVALH EH
								ON EH.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
								AND EH.request_no = <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
								AND EH.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
							LEFT JOIN TPMDPERFORMANCE_EVALD ED
								ON ED.form_no = EH.form_no
								AND ED.company_code = EH.company_code
								AND ED.lib_code = Z.apprlib_code
								AND upper(ED.lib_type) = <cfqueryparam value="#arguments.compcode#" cfsqltype="cf_sql_varchar">
								<cfif varcocode eq request.scookie.cocode>
									<cfif len(arguments.reviewerempid)>
										<cfif showFromLastReviewer eq 1 and len(arguments.lastreviewer)>
											AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.lastreviewer#" list="yes" cfsqltype="cf_sql_varchar">)
										<cfelse>
											AND ED.reviewer_empid IN (<cfqueryparam value="#arguments.reviewerempid#" list="yes" cfsqltype="cf_sql_varchar">)
										</cfif>
									</cfif>
								</cfif>
							</cfif>
					
							LEFT JOIN TPMDPERIODAPPRLIB APPR
								ON APPR.apprlib_code = Z.apprlib_code
								AND APPR.period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
								AND APPR.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
								AND APPR.reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
							LEFT JOIN TPMDPERIODAPPRAISAL PA
								ON PA.period_code = APPR.period_code
								AND PA.company_code =APPR.company_code
								AND PA.reference_date = APPR.reference_date
								AND PA.position_id = <cfqueryparam value="#empposid#" cfsqltype="cf_sql_integer">
								AND PA.apprlib_code = APPR.apprlib_code
							ORDER BY   Z.depth, Z.order_no, Z.appraisal_name
						</cfquery>
	
	    			</cfif> <!---riz--->
	    			
	            </cfif>
			
				
				<cfif not listfindnocase("PERSKPI",ucase(compcode))>
					<!---- start -lena- : reorder library per parent and child ---->
					<cfquery name="LOCAL.qGetCategoryFormData" dbtype="query">
						SELECT * FROM qGetApprDefault where pcode = 0 OR iscategory = 'Y' order by depth, <cfif isDefined('qGetApprDefault.order_no')>order_no,</cfif>  libname
					</cfquery>
					<cfif qGetCategoryFormData.recordcount gt 0>
						<cfset local.clDataNew = qGetApprDefault.ColumnList >
						<cfset LOCAL.qEmpFormDataNew = queryNew(clDataNew)> 
						<cfloop query="#qGetCategoryFormData#">
							<cfset LOCAL.temp = QueryAddRow(qEmpFormDataNew)>
							<cfloop list="#clDataNew#" index="idxColName">
								<cfset temp = QuerySetCell(qEmpFormDataNew,idxColName,evaluate("qGetCategoryFormData.#idxColName#"))/>
							</cfloop>
							<cfquery name="LOCAL.qGetSubFormData" dbtype="query">
								SELECT * FROM qGetApprDefault where pcode = '#qGetCategoryFormData.libcode#' and (iscategory = 'N' OR iscategory is null OR iscategory = '')
								order by depth, <cfif isDefined('qGetApprDefault.order_no')>order_no,</cfif> libname
							</cfquery>
							<cfif qGetSubFormData.recordcount gt 0>
								<cfloop query="#qGetSubFormData#">
									<cfset LOCAL.temp = QueryAddRow(qEmpFormDataNew)>
									<cfloop list="#clDataNew#" index="idxColName">
										<cfset temp = QuerySetCell(qEmpFormDataNew,idxColName,evaluate("qGetSubFormData.#idxColName#"))/>
									</cfloop>
								</cfloop>
							</cfif>
						</cfloop>
						<cfreturn qEmpFormDataNew>
					<cfelse>
						<cfreturn qGetApprDefault>
					</cfif>
					<!---- end -lena- : reorder library per parent and child ---->
				</cfif>
				
			   
			</cfif>
	       
	    </cffunction>
	    
	    <cffunction name="getEmpNoteData">
	        <cfargument name="periodcode" default="">
	        <cfargument name="refdate" default="">
	        <cfargument name="lstreviewer" default="">
	        <cfargument name="formno" default="">
	        <cfargument name="planformno" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#">
	        <cfif not len(formno)>
	            <cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
		            SELECT note_name, note_order, '' note_answer, '#request.scookie.user.empid#' AS rvid FROM TPMDPERIODNOTE
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		       </cfquery>
	        <cfelse>
				<cfset local.newlstrev = "">
				<cfloop list="#arguments.lstreviewer#" index="local.idxreviewer">
					<cfquery name="Local.qCheckStat" datasource="#request.sdsn#">
						SELECT head_status FROM TPMDPERFORMANCE_EVALH
						WHERE form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
						AND reviewer_empid = <cfqueryparam value="#idxreviewer#" cfsqltype="cf_sql_varchar">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfif (qCheckStat.head_status eq 1 AND idxreviewer neq REQUEST.SCOOKIE.USER.EMPID) OR ((qCheckStat.head_status eq 0 OR qCheckStat.head_status eq 1) AND idxreviewer eq REQUEST.SCOOKIE.USER.EMPID)>
						<cfset local.newlstrev = ListAppend(newlstrev, idxreviewer)/>
					</cfif>
				</cfloop>
				<cfif newlstrev neq "">
					<cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
						SELECT note_name, note_order, note_answer, reviewer_empid AS rvid FROM TPMDPERFORMANCE_EVALNOTE
						WHERE form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
						AND reviewer_empid IN (<cfqueryparam value="#newlstrev#" list="yes" cfsqltype="cf_sql_varchar">)
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfif qGetEvalNote.recordcount eq 0>
						<cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
						SELECT note_name, note_order, '' note_answer, '#request.scookie.user.empid#' AS rvid FROM TPMDPERIODNOTE
						WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
						AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
						AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
						</cfquery>
					</cfif>
				<cfelse>
					<cfquery name="Local.qGetEvalNote" datasource="#request.sdsn#">
					SELECT note_name, note_order, '' note_answer, '#request.scookie.user.empid#' AS rvid FROM TPMDPERIODNOTE
					WHERE period_code = <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
					AND reference_date = <cfqueryparam value="#arguments.refdate#" cfsqltype="cf_sql_timestamp">
					AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
					</cfquery>
				</cfif>
		        
	        </cfif>
	        <cfreturn qGetEvalNote>
	    </cffunction>
	    
	    
	    <!--- FUNGSI-FUNGSI CUSTOM REQUEST --->
	    <cffunction name="Approve">
	        <cfreturn true>
	    </cffunction>

		<cffunction name="FullyApprovedProcess" access="public">
			<cfargument name="strRequestNo" type="string" required="yes">
			<cfargument name="iApproverUserId" type="string" required="yes">
			<cfargument name="strckFormApprove" type="struct" required="no">
			<cfquery name="Local.qCheckIfRequestHasBeenApproved" datasource="#request.sdsn#">
				SELECT DISTINCT reviewer_empid, isfinal, reviewee_empid, head_status FROM TPMDPERFORMANCE_EVALH
			    WHERE request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
	            	AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			</cfquery>
	        <cfif qCheckIfRequestHasBeenApproved.recordcount>
	        	<!--- Update Final Record --->
	            <cfquery name="local.qGetFinalRecord" dbtype="query">
	            	SELECT * FROM qCheckIfRequestHasBeenApproved
	                WHERE reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfif qGetFinalRecord.recordcount and qGetFinalRecord.isfinal eq 0>
			        <cfquery name="local.qUpdatePMReqForm" datasource="#request.sdsn#">
						UPDATE TPMDPERFORMANCE_EVALH
			            SET isfinal = 1
					    WHERE request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
			                AND reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
			        </cfquery>
			        
			        <!--- yan tambahan yang send dari draft --->
			        <cfquery name="local.qCheckIfExistsInFinal" datasource="#request.sdsn#">
			            SELECT F.form_no,F.company_code,EH.score, EH.conclusion
			            FROM TPMDPERFORMANCE_FINAL F
			            LEFT JOIN TPMDPERFORMANCE_EVALH EH ON F.form_no = EH.form_no AND F.company_code = EH.company_code
			            WHERE EH.request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
			                AND EH.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			                AND EH.reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
			        </cfquery>
			        <cfif not qCheckIfExistsInFinal.recordcount>
			            <cfquery name="local.qInsertFinal" datasource="#request.sdsn#">
			                INSERT INTO TPMDPERFORMANCE_FINAL
	                    	(
	                    	form_no, company_code, period_code, reference_date,
	                    	reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode,
	                    	final_score, final_conclusion, created_by, created_date,
	                    	modified_by, modified_date,
	                    	ori_conclusion, adjust_no, ori_score
	                    	)
	                        SELECT form_no, company_code, period_code, reference_date, 
	                        	reviewee_empid, reviewee_posid, reviewee_grade, reviewee_employcode, 
	                        	score, conclusion, '#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>, 
	                        	'#request.scookie.user.uname#', <cfif request.dbdriver EQ "MSSQL">getdate()<cfelse>now()</cfif>,
	                        	conclusion, NULL adjust_no, score
	                        FROM TPMDPERFORMANCE_EVALH
	                        WHERE request_no = <cfqueryparam value="#strRequestNo#" cfsqltype="cf_sql_varchar">
			                    AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
			                    AND isfinal = 1
			            </cfquery>
			        </cfif>
			        <!--- --->
	            </cfif>
	            
	            <!--- DELETE RECORD yang di SKIP --->
	            <cfquery name="local.qGetSkipRecord" dbtype="query">
	            	SELECT reviewer_empid FROM qCheckIfRequestHasBeenApproved
	                WHERE head_status = 0
	            </cfquery>
	            <cfset Local.LstReviewerSkipped = valuelist(qGetSkipRecord.reviewer_empid)>
	            <cfif listlen(LstReviewerSkipped)>
	            	<!--- harusnya hapus data-data untuk empid tersebut --->
	            </cfif>
	        </cfif>
	        
			<cfreturn>
		</cffunction>

       <cffunction name="SendToNext">
	    	<cfparam name="sendtype" default="next">
			 <cfparam name="listPeriodComponentUsed" default="">
			<cfset local.strckData = FORM/>
			<cfset var objRequestApproval = CreateObject("component", "SFRequestApproval").init(false) /><!---TCK1908-0518296 set ke false untuk skip approver ketika step workflow approval tidak ditemukan employeenya--->
			<cfset Local.temp_outs_list = "">
			<cfquery name="local.qCekPMReqStatus" datasource="#request.sdsn#">
				SELECT DISTINCT reqemp, status, approval_list, outstanding_list FROM TCLTREQUEST
				WHERE req_type = 'PERFORMANCE.EVALUATION'
					AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
					AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> <!---modified by  ENC51115-79853 --->
					AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> <!---modified by  ENC51115-79853 --->
			</cfquery>			
            <!---- start : check if reviewee is active employee ---->
            <cfset LOCAL.strMessage = Application.SFParser.TransMLang("JSThis action can not be done, because employee is inactive", true)>
            <cfif reviewee_empid neq "" > 
                <cfquery name="LOCAL.qCheckEmployee" datasource="#REQUEST.SDSN#">
                    SELECT emp_no from teodempcompany where emp_id = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
					and status = 1
					<cfif request.dbdriver eq "MSSQL">
						AND (end_date >= getdate() OR end_date IS NULL)
					<cfelseif request.dbdriver eq "MYSQL">
						AND (end_date >= NOW() OR end_date IS NULL)
					</cfif>
                </cfquery>
                <cfif qCheckEmployee.recordcount eq 0>
    				<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
            			<cfoutput>
            				<script>
            					alert("#strMessage#");
            					parent.refreshPage();
            					parent.popClose();
            				</script>
            			</cfoutput>
    				<cfelse>
			            <cfset data = { MSG="#strMessage#", "success"="0" }>
                        <cfset serializedStr = serializeJSON(data)>
    					<cfoutput>
    						#serializedStr#
    					</cfoutput>
    				</cfif>
    				
        			<cf_sfabort>
                </cfif>
            </cfif>		
			<!---- end : check if reviewee is active employee ---->		
            			
           
            <!---Chcek is planning already fullyApproved--->
          
            <cfset LOCAL.strMessage = Application.SFParser.TransMLang("JSPerformance Planning is not Fully approved yet", true)>
            <cfif formno NEQ '' AND ( ListfindNoCase(listPeriodComponentUsed,'ORGKPI')  OR ListfindNoCase(listPeriodComponentUsed,'PERSKPI') ) > 
				
                <cfquery name="LOCAL.qCheckPlanning" datasource="#REQUEST.SDSN#">
                    SELECT FORM_NO FROM TPMDPERFORMANCE_PLANH
                    INNER JOIN TCLTREQUEST 
                    	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_PLANH.request_no
                    WHERE TCLTREQUEST.status NOT IN (9,3)
                    AND FORM_NO = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
                </cfquery>
				
					
                <cfif qCheckPlanning.recordcount gt 0>

    				<cfif REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE eq 0>
            			<cfoutput>
            				<script>
            					alert("#strMessage#");
            					parent.refreshPage();
            					parent.popClose();
            				</script>
            			</cfoutput>
    				<cfelse>
			            <cfset data = { MSG="#strMessage#", "success"="0" }>
                        <cfset serializedStr = serializeJSON(data)>
    					<cfoutput>
    						#serializedStr#
    					</cfoutput>
    				</cfif>        			
        			
        			<cf_sfabort>
                </cfif>
				
            </cfif>
            <!---Chcek is planning already fullyApproved--->
			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
				SELECT  position_id FROM TEODEMPCOMPANY WHERE emp_id = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
				AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> 
				and status = 1
			</cfquery>
			<cfif qDetailReviewee.recordcount eq 0>
    			<cfquery name="local.qDetailReviewee" datasource="#request.sdsn#">
    				SELECT  grade_code, employ_code, position_id 
    				FROM TEODEMPCOMPANY 
    				WHERE emp_id = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
    				and status = 1
    			</cfquery>
			</cfif>

			<cfset local.retvar = true>

			<cfif (listfindnocase(ucase(listPeriodComponentUsed),"ORGKPI") or listfindnocase(ucase(listPeriodComponentUsed),"PERSKPI"))>
				<cfset retvar = cekOrgPersKPI(period_code,reference_date,reviewee_empid,qDetailReviewee.position_id,REQUEST.SCOOKIE.COID,REQUEST.SCOOKIE.COCODE)> 
			</cfif>
				<cfif retvar eq false>
				<cfoutput>
					<script>
						
						parent.refreshPage();
							parent.popClose();
					</script>
				</cfoutput>
				<cf_sfabort>
				</cfif>
			
	        <cfif sendtype neq 'draft'>
					
                <cfif qCekPMReqStatus.status eq 0> 
						<cfset local.tempOutstanding = 1>
						<cfset local.tempStatus = 2>
						<cfif ListLast(strckData.FullListAppr) eq qCekPMReqStatus.reqemp>
							<cfset tempStatus = 3>
							<cfset tempOutstanding = 0>
						</cfif>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TPMDPERFORMANCE_EVALNOTE
								WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TPMDPERFORMANCE_EVALD
								WHERE form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
								AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TPMDPERFORMANCE_EVALH
								WHERE request_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
								AND form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
								AND period_code =  <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
								AND reference_date = <cfqueryparam value="#reference_date#" cfsqltype="cf_sql_timestamp">
								AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar">
							</cfquery>
							<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">
								DELETE FROM TCLTREQUEST
								WHERE req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
							</cfquery>
							
							<cfif not structkeyexists(strckData,"persKPIArray")>
							<cfelse>
								<cfset strckData.persKPIArray = Replace(strckData.persKPIArray, "\r\n", " ","all")>
							</cfif>
							<cfif not structkeyexists(strckData,"competencyArray")>
							<cfelse>
								<cfset strckData.competencyArray = Replace(strckData.competencyArray, "\r\n", " ","all")>
							</cfif>
							<cfset Add()>
				<cfelse>
						    <cfif qCekPMReqStatus.status eq 4 and listlen(qCekPMReqStatus.outstanding_list)>
								<cfset temp_outs_list = qCekPMReqStatus.outstanding_list>
								<cfset temp_outs_list = listdeleteat(temp_outs_list,listfindnocase(temp_outs_list,REQUEST.SCOOKIE.USER.UID,","))>
							</cfif>
							
							<cfif len(temp_outs_list)>
								<!----<cf_sfwritelog dump="temp_outs_list" prefix="temp_outs_list">---->
								<cfquery name="local.qUpdApprovedData" datasource="#request.sdsn#">
									UPDATE TCLTREQUEST
									SET outstanding_list = <cfqueryparam value="#temp_outs_list#" cfsqltype="cf_sql_varchar">,
									
									<cfif qCekPMReqStatus.reqemp eq REQUEST.SCOOKIE.USER.EMPID>
										status = 1,
									<cfelse>
										status = 2,
									</cfif>
									
									modified_by = <cfqueryparam value="#request.scookie.user.uname#" cfsqltype="cf_sql_varchar">,
									modified_date = <cfqueryparam value="#createodbcdatetime(now())#" cfsqltype="cf_sql_timestamp">		
									WHERE req_type = 'PERFORMANCE.EVALUATION'
										AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
										AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> 
										AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> 
								</cfquery>
							</cfif>
							
							<cfset local.valret = objRequestApproval.ApproveRequest(request_no, REQUEST.SCookie.User.uid, true) />
							<cfif not isBoolean(valret)>
							<cfelse>
    							<cfif valret>
    								<cfquery name="local.qCekPMReqStatus" datasource="#request.sdsn#">
    									SELECT status FROM TCLTREQUEST
    									WHERE req_type = 'PERFORMANCE.EVALUATION'
    										AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
    										AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> 
    										AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> 
    							
    								</cfquery>
    								<cfif qCekPMReqStatus.status eq 3>
    									<cfset sendtype = 'final'>
    									<cfset strckData.isfinal = 1/>
    									<cfset strckData.head_status = 1/>
    								</cfif>
    							</cfif>
							</cfif>
							
							
                            <!--- TCK0818-81809 (Revise) | Send to next delete EVALH and EVALD Higher Approver --->
                        	<cfquery name="local.qSelStepHigher" datasource="#request.sdsn#">
                            	SELECT reviewer_empid FROM TPMDPERFORMANCE_EVALH 
                            	WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                            	AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
                            	AND review_step > <cfqueryparam value="#strckData.USERINREVIEWSTEP#" cfsqltype="cf_sql_varchar">
                            	AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                            </cfquery>
                            
                            <cfloop query="qSelStepHigher">
                        	    <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
                            	    DELETE FROM  TPMDPERFORMANCE_EVALD 
                            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
                            	    AND company_code =  <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                                </cfquery>
                                
                                <cfquery name="local.qDelPlanD" datasource="#request.sdsn#">
                            	    DELETE FROM  TPMDPERFORMANCE_EVALH 
                            		WHERE form_no = <cfqueryparam value="#strckData.formno#" cfsqltype="cf_sql_varchar">
                            		AND request_no = <cfqueryparam value="#strckData.request_no#" cfsqltype="cf_sql_varchar">
                            		AND reviewer_empid = <cfqueryparam value="#qSelStepHigher.reviewer_empid#" cfsqltype="cf_sql_varchar">
                            	    AND company_code = <cfqueryparam value="#form.cocode#" cfsqltype="cf_sql_varchar">
                                </cfquery>
                            </cfloop>
                            <!--- TCK0818-81809 (Revise) | Send to next delete EVALH and EVALD Higher Approver --->
							
							<cfset SaveTransaction(50,strckData)/>
				</cfif>
				
                <cfset LOCAL.allowskipCompParam = "Y">
                <cfset LOCAL.requireselfassessment = 1>
                <cfquery name="LOCAL.qCompParam" datasource="#request.sdsn#">
                	SELECT field_value, UPPER(field_code) field_code from tclcappcompany where UPPER(field_code) IN ('ALLOW_SKIP_REVIEWER', 'REQUIRESELFASSESSMENT') and company_id = '#REQUEST.SCookie.COID#'
                </cfquery>
                
                <cfloop query="qCompParam">
                    <cfif TRIM(qCompParam.field_code) eq "ALLOW_SKIP_REVIEWER" AND TRIM(qCompParam.field_value) NEQ ''>
                    	<cfset allowskipCompParam = TRIM(qCompParam.field_value)>
                    <cfelseif TRIM(qCompParam.field_code) eq "REQUIRESELFASSESSMENT" AND TRIM(qCompParam.field_value) NEQ '' >
                    	<cfset requireselfassessment = TRIM(qCompParam.field_value)> <!---Bypass self assesment--->
                    </cfif>
                </cfloop>
    		    <!---Get alloskip param--->
    		    
    		    <!---Get status Request--->
				<cfquery name="local.qCekPMReqCurrentStatus" datasource="#request.sdsn#">
					SELECT status FROM TCLTREQUEST
					WHERE req_type = 'PERFORMANCE.EVALUATION'
						AND req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
						AND company_id = <cfqueryparam value="#strckData.COID#" cfsqltype="cf_sql_integer"> 
						AND company_code = <cfqueryparam value="#strckData.cocode#" cfsqltype="cf_sql_varchar"> 
				</cfquery>
    		    <!---Get status Request--->
    		    
                <cfif qCekPMReqCurrentStatus.status EQ 3 > <!---Validasi Jika fully approved--->
                    <cfset LOCAL.additionalData = StructNew() >
                    <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                    
                    <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                        template_code = 'PerformanceEvalNotifFullyApproved', 
                        lstsendTo_empid = reviewee_empid , 
                        reviewee_empid = reviewee_empid ,
                        strckData = additionalData
                    )>
                <cfelseif val(FORM.UserInReviewStep)+1 LTE Listlen(FORM.FullListAppr) > <!---Validasi ada next approver--->
                    <cfif allowskipCompParam EQ 'N' > <!---Tidak bisa skip harus berurutan--->
        		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep)+1 )><!---hanya get list next approver--->
                    <cfelse>
        		        <cfset LOCAL.lstNextApprover = ''><!---all approver dikirim--->
                        <cfloop index="LOCAL.idx" from="#val(FORM.UserInReviewStep)+1#" to="#Listlen(FORM.FullListAppr)#" >
        		            <cfset tempList = ListGetAt( FORM.FullListAppr , idx )><!---get list next approver--->
    		                <cfset lstNextApprover = ListAppend(lstNextApprover,tempList) ><!---all approver dikirim--->
                        </cfloop>
                    </cfif>
                    
                    <cfset LOCAL.additionalData = StructNew() >
                    <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                    
                    <cfif lstNextApprover NEQ ''>
                        <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                        <cfif reviewee_empid EQ request.scookie.user.empid> <!--- Send by reviewee status not requested --->
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalSubmitByReviewee', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        <cfelse><!--- Send by approver status not requested --->
                        
                            <cfif ListLast(FORM.FullListAppr) EQ lstNextApprover>
                                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                    template_code = 'PerformanceEvalSubmitToLastApprover', 
                                    lstsendTo_empid = lstSendEmail , 
                                    reviewee_empid = reviewee_empid ,
                                    strckData = additionalData
                                )>
                            <cfelse>
                                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                    template_code = 'PerformanceEvalSubmitByApprover', 
                                    lstsendTo_empid = lstSendEmail , 
                                    reviewee_empid = reviewee_empid ,
                                    strckData = additionalData
                                )>
                            </cfif>
                        </cfif>
                    </cfif>
                </cfif>
				<!--- Notif here --->
				
	        <cfelse>
		        <cfset SaveTransaction(50,strckData)/>
				
	        </cfif>
	        
	        <!--- Tampilkan Alert ketika ada yang di skip --->
	        <cfif sendtype neq 'draft'>
    	        <cfquery name="LOCAL.qGetApprInfo" datasource="#request.sdsn#">
                    SELECT reviewer_empid, review_step, head_status FROM TPMDPERFORMANCE_EVALH 
                    WHERE  request_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
                        AND form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
    	        </cfquery>
    	        <cfquery name="LOCAL.qGetCurrApprInfo" dbtype="query">
                    SELECT reviewer_empid, review_step, head_status FROM qGetApprInfo 
                    WHERE  reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
    	        </cfquery>
    	        <cfquery name="LOCAL.cekApprover" dbtype="query">
                    SELECT * FROM qGetApprInfo 
                    WHERE reviewer_empid <> <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
                       AND review_step < <cfqueryparam value="#qGetCurrApprInfo.review_step#" cfsqltype="cf_sql_varchar">
                       AND head_status = 0
    	        </cfquery>
    	        <cfif cekApprover.recordcount neq 0>
        			<cfoutput>
        				<script>
        					alert("#Application.SFParser.TransMLang("JSThere are some approver skipped", true)#");
        				</script>
        			</cfoutput>
    	        </cfif>
	        </cfif>
	        <!--- Tampilkan Alert ketika ada yang di skip --->
			<cfquery name="LOCAL.qGetDataRequest" datasource="#request.sdsn#">
                SELECT seq_id, req_no, status,outstanding_list, company_id, email_list, approval_list FROM TCLTREQUEST 
                WHERE  req_no = <cfqueryparam value="#request_no#" cfsqltype="cf_sql_varchar">
	        </cfquery> 
	        <cfif sendtype eq 'draft'>
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Save Request as Draft", true)>
	        <cfelseif sendtype eq 'final' OR qGetDataRequest.status EQ 3 >
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Save Request as Final Conclusion", true)>
				<!--- <cfset tempSendEmail = SendEmail(qGetDataRequest.req_no, qGetDataRequest.status,qGetDataRequest.email_list,qGetDataRequest.seq_id,qGetDataRequest.company_id) /> --->
	        <cfelse>
				<cfset local.strMessage = Application.SFParser.TransMLang("JSSuccessfully Send Request to Next Reviewer", true)>
				<!--- <cfset tempSendEmail = NewRequestNotif({mailtmpltRqster="",mailtmpltRqstee="",mailtmpltAprvr="NewRequestNotification",notiftmpltRqster="",notiftmpltRqstee="",notiftmpltAprvr="3",strRequestNo=qGetDataRequest.req_no,iStatusOld=qGetDataRequest.status,lstNextApprover=qGetDataRequest.outstanding_list,requestcoid=qGetDataRequest.company_id,requestId=qGetDataRequest.seq_id,lastOutstanding=ListLast(qGetDataRequest.outstanding_list)})> --->
	        </cfif>
	        <cfset flagnewui = "#REQUEST.CONFIG.NEWLAYOUT_PERFORMANCE#">
	        <cfif REQUEST.SCOOKIE.MODE EQ "SFGO">
					<cfset LOCAL.scValid={result="#strMessage#"}>
					<cfreturn scValid/>
			<cfelse>
    	        <cfif flagnewui eq 0>
        			<cfoutput>
        				<script>
        					alert("#strMessage#");
        					parent.refreshPage();
        					parent.popClose();
        				</script>
        			</cfoutput>
        		<cfelseif flagnewui eq 1>
        		    <cfset data = {"success"="1","request_no"="#request_no#","form_no"="#formno#", "MSG"="#strMessage#"}>
                    <cfset serializedStr = serializeJSON(data)>
        		    <cfoutput>
        		        #serializedStr#
        		    </cfoutput>
    			</cfif>
			</cfif>
			
	    </cffunction>
	    <cffunction name="ApprovalLoop">
	    	<cfargument name="wdappr" required="yes">
	    	<cfargument name="empid" required="yes">
	    	<cfargument name="ListEmpFinishedReview" default="" required="no">
	        <cfset Local.empinstep = 0>
	        <cfset Local.ApproverList = "">
	        <cfset Local.ApprovedStepList = "">
	        <cfset Local.isbreak = false>
	        <!--- looping step --->
	        <cfloop index="local.idx" from="1" to="#ArrayLen(wdappr)#">
	        	<cfif ArrayLen(wdappr[idx].approver) gt 1>
	            	<cfset local.LstTemp=""/>
			        <!--- looping share approver --->
	            	<cfloop index="local.idx2" from="1" to="#ArrayLen(wdappr[idx].approver)#">
	                    <cfif ArrayLen(wdappr[idx].approver[idx2]) gt 1>
			            	<cfset local.LstTemp2=""/>
			                <!--- looping share position --->
		                	<cfloop index="local.idx3" from="1" to="#ArrayLen(wdappr[idx].approver[idx2])#">
				            	<cfset LstTemp2 = ListAppend(LstTemp2,wdappr[idx].approver[idx2][idx3].emp_id,"|")/> <!---";" diganti biar sama--->
	                            <cfif empid eq wdappr[idx].approver[idx2][idx3].emp_id and not isbreak>
	                            	<cfset empinstep = idx />
							        <cfset isbreak = true>
	                            </cfif>
		                    </cfloop>
		            		<cfset LstTemp = ListAppend(LstTemp,LstTemp2,"|")/>
	                    <cfelse>
			            	<cfset LstTemp = ListAppend(LstTemp,wdappr[idx].approver[idx2][1].emp_id,"|")/>
	                        <cfif empid eq wdappr[idx].approver[idx2][1].emp_id and not isbreak>
	                          	<cfset empinstep = idx />
						        <cfset isbreak = true>
	                        </cfif>
	                    </cfif>
	                </cfloop>
	            	<cfset ApproverList = ListAppend(ApproverList,LstTemp)/>
	            <cfelse>
		        	<cfif ArrayLen(wdappr[idx].approver[1]) gt 1>
		            	<cfset LstTemp=""/>
		                <!--- looping share position --->
	                	<cfloop index="local.idx22" from="1" to="#ArrayLen(wdappr[idx].approver[1])#">
	                       	<cfset LstTemp = ListAppend(LstTemp,wdappr[idx].approver[1][idx22].emp_id,"|")/> <!---";" diganti biar sama--->
	                        <cfif empid eq wdappr[idx].approver[1][idx22].emp_id and not isbreak>
	                          	<cfset empinstep = idx />
						        <cfset isbreak = true>
	                        </cfif>
	                    </cfloop>
		            	<cfset ApproverList = ListAppend(ApproverList,LstTemp)/>
	                <cfelse>
		            	<cfset ApproverList = ListAppend(ApproverList,wdappr[idx].approver[1][1].emp_id)/>
	                    <cfif empid eq wdappr[idx].approver[1][1].emp_id and not isbreak>
	                      	<cfset empinstep = idx />
					        <cfset isbreak = true>
	                    </cfif>
	                </cfif>
	            </cfif>
	        </cfloop>
	        <cfset local.strckApprCekReturn = structnew()/>
	        <cfset strckApprCekReturn.empinstep = empinstep/>
	        <!---<cfset strckApprCekReturn.approvedsteplist = ApprovedStepList/>--->
	        <cfset strckApprCekReturn.fullapproverlist = ApproverList/>
	        <cfreturn strckApprCekReturn>
	    </cffunction>
	    
	  <cffunction name="GetApproverList">
	    	<cfargument name="empid" required="yes">
	    	<cfargument name="reqno" default="">
	    	<cfargument name="emplogin" default="#request.scookie.user.empid#">
	    	<cfargument name="reqorder" default="-">
			<cfargument name="varcoid" default="#request.scookie.coid#"  required="no">
			<cfargument name="varcocode" default="#request.scookie.cocode#"  required="no">
			
	       	<!--- cek kalo request sudah pernah dibuat --->
	        <cfquery name="local.qCheckRequest" datasource="#request.sdsn#">
	        	SELECT requester, approval_data, approval_list, approved_list, outstanding_list, status FROM TCLTREQUEST
	            WHERE company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_integer">
		            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		            AND req_type = 'PERFORMANCE.EVALUATION'
		            AND req_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
		            AND reqemp = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
					and req_no <> '' <!--- YH --->
	        </cfquery>
	        
	        <!--- cari yang sudah pernah isi dan statusnya--->
	        <cfquery name="Local.qCheckEmpFilled" datasource="#request.sdsn#">
	        	SELECT *
	            FROM TPMDPERFORMANCE_EVALH
	            WHERE company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	            AND request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	            AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            
	            <!--- artinya yang statusnya masih draft di skip kalo status requestnya selain revised --->
	           	<cfif qCheckRequest.status neq 4> <!--- ini butuh hapus record yg statusnya draft tapi stepnya diskip --->
	            AND (
					head_status = 1
					OR
					reviewer_empid = <cfqueryparam value="#emplogin#" cfsqltype="cf_sql_varchar">
	            )
	            </cfif>
	            <!--- [Q} pertanyaan, jika sudah final, apakah yang head statusnya = 0 ini dihapus saja ? [A] : Ya--->
	            
	            ORDER BY review_step ASC
	        </cfquery>
	        
	        <!--- merupakan list empid yang sudah pernah buat untuk reqno tersebut --->
	        <cfset local.ListFilledEmp = valuelist(qCheckEmpFilled.reviewer_empid)/>
	        <!--- merupakan list review step yang sudah pernah buat untuk reqno tersebut --->
	        <cfset local.ListFilledEmpStep = valuelist(qCheckEmpFilled.review_step)/>
	        
	        <!--- merupakan list head_status yang sudah pernah buat untuk reqno tersebut --->
	        <cfset local.ListHeadStatus = valuelist(qCheckEmpFilled.head_status)/>
	        
	   		<cfif qCheckRequest.recordcount>
				<cfset Local.strckResultRequestApproval = StructNew() />
	            <cfif len(qCheckRequest.approval_data)>
					<cfset LOCAL.wdapproval=SFReqFormat(qCheckRequest.approval_data,"R",[])>
	            	<!---TW:<cfwddx action="wddx2cfml" input="#qCheckRequest.approval_data#" output="wdapproval">--->
					<cfset strckResultRequestApproval.wdapproval = wdapproval/>
	            <cfelse><!--- status dari request masih draft --->
					<cfset strckResultRequestApproval = objRequestApproval.Generate("PERFORMANCE.EVALUATION", emplogin, empid, reqorder) />
	            </cfif>
				<cfset strckResultRequestApproval.approval_list = qCheckRequest.approval_list/>
				<cfset strckResultRequestApproval.outstanding_list = qCheckRequest.outstanding_list/>
				<cfset strckResultRequestApproval.requester = qCheckRequest.requester/>
				<cfset strckResultRequestApproval.status = qCheckRequest.status/>
	        <cfelse>
				<cfset Local.strckResultRequestApproval = StructNew() />
				<cfset strckResultRequestApproval = objRequestApproval.Generate("PERFORMANCE.EVALUATION", emplogin, empid, reqorder) />
				<cfif not isBoolean(strckResultRequestApproval)>
				<cfset strckResultRequestApproval.approval_list = ""/>
				<cfset strckResultRequestApproval.requester = ""/>
				<cfset strckResultRequestApproval.status = ""/>
				<cfset strckResultRequestApproval.outstanding_list = ""/>
				</cfif>
				
	        </cfif>
	        <cfif not isBoolean(strckResultRequestApproval)>
				<cfset local.strckAppr = ApprovalLoop(strckResultRequestApproval.wdapproval,emplogin)/>
				<cfset local.userinstep = strckAppr.empinstep/>
				<cfset local.full_list_approver = strckAppr.fullapproverlist/>
			<cfelse>
				<cfset userinstep = 0/>
				<cfset full_list_approver = ""/>
			</cfif>
	        <cfset local.list_approver = full_list_approver/>
	        
	        <!--- APPROVER IS REVIEWEE --->
	        <cfset local.reviewee_in_step = listfindnocase(full_list_approver,empid,",|")>
	        <cfif reviewee_in_step gte 1> <!--- sebelumnya gt tanpa e [YAN]--->
	            <cfset local.approver_is_reviewee = 1/>
	        <cfelse>
		        <cfset local.approver_is_reviewee = 0/>
	        </cfif>
	        
	        <!--- REVIEWEE AS APPROVER --->
	        <cfif approver_is_reviewee>
	        	<cfset local.reviewee_as_approver = 0>
	        <cfelseif (emplogin eq empid and approver_is_reviewee eq 0) or (listfindnocase(ListFilledEmp,empid))>
	        	<cfset reviewee_as_approver = 1>
	        	<cfset list_approver = listprepend(full_list_approver,empid)>
	            <cfset full_list_approver = list_approver>
                <cfif userinstep neq 0 OR request.scookie.user.empid eq empid> <!---Replace Approver--->
    	            <cfset ++userinstep/>
    	        </cfif>
	        <cfelse>
	        	<cfset reviewee_as_approver = 0>
	        </cfif>

	        <cfloop list="#list_approver#" index="local.listempinstepno">
	           	<cfloop list="#listempinstepno#" delimiters="|" index="local.cekidx">
	               	<cfif listfindnocase(ListFilledEmp,cekidx)>
	                   	<cfset list_approver = listsetat(list_approver,listfindnocase(list_approver,listempinstepno),cekidx)/>
	                    <cfbreak>
	                <cfelseif cekidx eq emplogin>
			           	<cfset list_approver = listsetat(list_approver,listfindnocase(list_approver,listempinstepno),request.scookie.user.empid)/>
	                    <cfbreak>
	                </cfif>
	            </cfloop>
	        </cfloop>
	        
	        <cfset local.list_approver_full = list_approver>
	        
	        <!--- hapus approver yang berada di step lebih tinggi dari user yang login --->
	        <cfif userinstep neq 0 and userinstep neq listlen(list_approver)>
	        	<cfloop index="local.rmv" from="#listlen(list_approver)#" to="#userinstep+1#" step="-1">
	            	<cfset list_approver = ListDeleteAt(list_approver,rmv)/>
	            </cfloop>
	        </cfif>

	        <!--- variabel ini digunakan untuk kasus step 2 melihat request yang sudah di approved oleh step di atasnya dan step 2 tidak melkukan penilaian --->
			<cfset local.higher_step_is_approving = 0>
	        
			<cfset local.step_to_viewed = "">
	        <cfloop list="#ListFilledEmpStep#" index="local.viewedstep">
	        	<cfif userinstep gt viewedstep>
					<cfset step_to_viewed = listappend(step_to_viewed,viewedstep)>
	        	<cfelseif userinstep eq viewedstep>
					<cfset step_to_viewed = listappend(step_to_viewed,viewedstep)>
					<cfset list_approver = listsetat(list_approver,viewedstep,listgetat(ListFilledEmp,listfindnocase(ListFilledEmpStep,viewedstep)))>
	            <cfelse>
	            	<cfset higher_step_is_approving = 1>
	            	<cfbreak>
	            </cfif>
	        </cfloop>
	        <cfif not isBoolean(strckResultRequestApproval)>
				<!--- kalo step si user ga ada di step yang udah pernah diisi (dan telah melewati prosesnya)--->
				<cfif not listfindnocase(step_to_viewed,userinstep) and userinstep neq 0>
				
					<!--- kalo status requestnya 3 ya hanya bisa liat saja untuk step sebelumnya, kalo status requestnya 4 dia bisa kembali isi, kalo selain itu dan higher approver sudah pernah menilai maka dia hanya bisa liat juga --->
					<cfif strckResultRequestApproval.status eq 4 or (strckResultRequestApproval.status neq 3 and not higher_step_is_approving)>
						<cfset step_to_viewed = listappend(step_to_viewed,userinstep)>
					</cfif>
				</cfif>
			</cfif>
	        
	       	<cfset local.new_list_approver = "">
	        <cfif len(list_approver)>
	        <cfloop list="#step_to_viewed#" index="local.idx">
	        	<cfset new_list_approver = listappend(new_list_approver,listgetat(list_approver,idx))>
	        </cfloop>
	        </cfif>
	        
	        <!--- untuk mencegah approver lain yang tidak menilai dapat menilai kembali, padahal statusnya adalah unfinalized --->
	        <cfif qCheckRequest.status eq 2>
		        <cfquery name="Local.qCheckAllEmpFilled" datasource="#request.sdsn#">
		        	SELECT *
		            FROM TPMDPERFORMANCE_EVALH
		            WHERE company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
		            AND request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
		            AND reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
		            ORDER BY review_step ASC
		        </cfquery>
	        	<cfquery name="Local.qLastApproverRecord" dbtype="query">
	            	SELECT MAX(review_step) AS stepmax FROM qCheckAllEmpFilled
	            </cfquery>
	        	<cfquery name="Local.qCekIfRequestIsUnfinal" dbtype="query">
	            	SELECT created_by, modified_by FROM qCheckAllEmpFilled
	                WHERE review_step = <cfqueryparam value="#qLastApproverRecord.stepmax#" cfsqltype="cf_sql_integer">
	            </cfquery>
	            <cfif qCekIfRequestIsUnfinal.recordcount and listfindnocase(qCekIfRequestIsUnfinal.modified_by,"UNFINAL","|")>
		        	<cfset step_to_viewed = "">
	            </cfif>
	        </cfif>

	       	<!--- ambil nilai head status --->
	       	<cfset local.approver_headstatus = -1/>
			<cfif listfindnocase(ListFilledEmp,emplogin)>
	        	<cfset approver_headstatus = listgetat(ListHeadStatus,listfindnocase(ListFilledEmp,emplogin))/>
	        </cfif>
	        
	        <!--- ambil nilai head status untuk approver sebelumnya --->
			<cfset local.approverbefore_headstatus = 0/>
	        
	        <cfif listlen(new_list_approver)>
		       	<cfset Local.approverbefore_empid = listlast(listdeleteat(new_list_approver,listlen(new_list_approver)))/>
				<cfif listfindnocase(ListFilledEmp,approverbefore_empid)>
		        	<cfset approverbefore_headstatus = listgetat(ListHeadStatus,listfindnocase(ListFilledEmp,approverbefore_empid))/>
		        </cfif>
	        </cfif>
	        
	        <cfset Local.lastApprover = "">
	        <cfif listlen(ListFilledEmp)>
	        	<cfset lastApprover = listlast(ListFilledEmp)>
	        </cfif>
	        
	        <cfset Local.revise_list_approver = "">
	        <cfset Local.revise_pos_atstep = 0>
			<cfif not isBoolean(strckResultRequestApproval)>
				<cfif strckResultRequestApproval.status eq 4>
					<cfquery name="local.qGetListEmpFilled" dbtype="query">
						SELECT * FROM qCheckEmpFilled
						<!--- WHERE head_status = 1 --->
						<!--- harusnya yang draft2 sebelumnya sudah di hapus --->
						ORDER BY review_step ASC
					</cfquery>
					<cfquery name="local.qGetMaxStepToDraft" dbtype="query">
						SELECT MIN(review_step) AS stepno FROM qGetListEmpFilled
						WHERE head_status = 0
					</cfquery>
					
					<cfset revise_list_approver = valuelist(qGetListEmpFilled.reviewer_empid)>
					<cfset revise_pos_atstep = qGetMaxStepToDraft.stepno>
				</cfif>
			<cfelse>
				 <cfset revise_list_approver = "">
				 <cfset revise_pos_atstep = 0>
			</cfif>
	        <cfset local.strckReturn = structnew()/>
	        <cfset strckReturn.index = userinstep/>
	        <cfset strckReturn.LstApprover = new_list_approver/>
	        <cfset strckReturn.FullListApprover = full_list_approver/>
			<cfset strckReturn.approver_headstatus = approver_headstatus/>
			<cfset strckReturn.approverbefore_headstatus = approverbefore_headstatus/>
			<cfif not isBoolean(strckResultRequestApproval)>
				<cfset strckReturn.status = strckResultRequestApproval.status/>
					<cfset strckReturn.current_outstanding_list = strckResultRequestApproval.outstanding_list/>
			<cfelse>
				<cfset strckReturn.status = strckResultRequestApproval/>
					<cfset strckReturn.current_outstanding_list = "">
			</cfif>
			<cfset strckReturn.reviewee_as_approver = reviewee_as_approver/>
			<cfset strckReturn.approver_is_reviewee = approver_is_reviewee/>
			<cfset strckReturn.step_to_viewed = step_to_viewed/>
			<cfset strckReturn.revise_list_approver = revise_list_approver/>
			<cfset strckReturn.revise_pos_atstep = revise_pos_atstep/>
			<cfset strckReturn.lastApprover = lastApprover/>
			
		
			<cfset strckReturn.higher_step_is_approving = higher_step_is_approving/>
	        
	        <cfreturn strckReturn/>
	    </cffunction>
	    
	    <cffunction name="getObjUnitObjective">
	    	<cfparam name="empid" default="">
	        <cfparam name="formno" default="">
	        <cfparam name="reqno" default="">
	        <cfparam name="periodcode" default="">
			<cfparam name="refdate" default="">
			<!--- add by Shinta 15 July 2014 --->
			<cfset local.appcode = 'PERFORMANCE.Evaluation'>
			<!---<cfquery name="local.qRequestApprovalOrder" datasource="#REQUEST.SDSN#">
				SELECT	seq_id,
						req_order,request_approval_name,
						request_approval_formula,requester,
						requestee FROM	TCLCReqAppSetting
				WHERE	company_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.scookie.COID#" />
				    AND request_approval_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#appcode#"/> 
				ORDER BY req_order DESC
			</cfquery>--->
		<!-----<cfset local.arrEmployee = objRequestApproval.GetEmployeeFromFormula(strRequestApprovalFormula=qRequestApprovalOrder.request_approval_formula,strEmpId=empid, iEmpType=0,retType="Isempid") />
			<cfset local.lstapprover = "">
			<cfloop array="#arrEmployee#" index="local.idxEmployee">
				<cfset lstapprover=listappend(lstapprover,'#idxEmployee['emp_id']#')>
			</cfloop>---->
			<cfset LOCAL.reqorderfix = getApprovalOrder(reviewee=empid,reviewer=REQUEST.scookie.user.empid)>
			
			<!---<cfset local.strckListApprover = GetApproverList(reqno=reqno,empid=empid,reqorder=qRequestApprovalOrder.req_order,varcoid=REQUEST.SCOOKIE.COID,varcocode=REQUEST.SCOOKIE.COCODE)>--->
			<cfset local.strckListApprover = GetApproverList(reqno=reqno,empid=empid,reqorder=reqorderfix,varcoid=REQUEST.SCOOKIE.COID,varcocode=REQUEST.SCOOKIE.COCODE)>
			<cfset local.lstapprover=strckListApprover.FULLLISTAPPROVER>
			<cfset local.cekapp = listfindnocase(lstapprover,#REQUEST.scookie.user.empid#)>
			<cfif cekapp EQ 0> <!---cek lagi yg spare--->
			    <cfset local.cekapp = listfindnocase(lstapprover,#REQUEST.scookie.user.empid#,'|')>
			</cfif>
			<cfif cekapp gt 0>
				<cfset local.approveryn = 1 >
			<cfelse>
				<cfset approveryn = 0 >
			</cfif>

			<!--- end --->
		    <cfquery name="local.gqetPos" datasource="#REQUEST.SDSN#">
	        	select distinct emp_id,position_id from teodempcompany
	            where emp_id = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
				and  company_id = #REQUEST.SCOOKIE.COID# 
	        </cfquery>
	        <cfquery name="local.qgetheadDiv"  datasource="#REQUEST.SDSN#">
	        	<!----select distinct position_id from teomposition
	            where head_div = <cfqueryparam value="#gqetPos.position_id#" cfsqltype="cf_sql_varchar">  --->
				select dept_id position_id from teomposition
	            where position_id = <cfqueryparam value="#gqetPos.position_id#" cfsqltype="cf_sql_varchar">
	        </cfquery>
			<cfset local.head_empid = qgetheadDiv.position_id>
			
			<cfset local.login_empid = #REQUEST.sCOOKIE.USER.empid#>
			<cfquery name="local.qPoslogin" datasource="#REQUEST.SDSN#">
				select distinct emp_id,position_id from teodempcompany
	            where emp_id = <cfqueryparam value="#login_empid#" cfsqltype="cf_sql_varchar">
				and  company_id = #REQUEST.SCOOKIE.COID# 
			</cfquery>
			<cfquery name="local.qHeadlogin" datasource="#REQUEST.SDSN#">
				 <!---select position_id from teomposition
	            where head_div = <cfqueryparam value="#qPoslogin.position_id#" cfsqltype="cf_sql_varchar"> ---->
				select dept_id position_id from teomposition
	            where position_id = <cfqueryparam value="#qPoslogin.position_id#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfset local.head_login = qHeadlogin.position_id>
			<cfif head_empid neq head_login>
				<cfset local.head_div = 0>
			<cfelse>
				<cfset local.head_div = 1>
			</cfif>
		
	        <cfif qgetheadDiv.recordcount eq 0 >
	        	<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSYou are not allowed to open this form",true)>
	            <cfoutput><script>alert("#SFLANG#");popClose(true);</script></cfoutput><CF_SFABORT>
	        <cfelse>
	        	<cfquery name="local.qCheckPlan" datasource="#REQUEST.SDSN#">
	                select distinct form_no
	                FROM TPMDPERFORMANCE_PLANKPI PLKPI
						INNER JOIN TCLTREQUEST R 
							ON R.req_no = PLKPI.request_no
							AND R.req_type = 'PERFORMANCE.PLAN'
							AND R.company_code = PLKPI.company_code
							AND R.status IN (3,9)
	                where  orgunit_id =<cfqueryparam value="#qgetheadDiv.position_id#" cfsqltype="cf_sql_integer">
	                AND period_code=<cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            
	             <cfif not qCheckPlan.recordcount>
		        	<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSOrganization Unit not yet have approved KPI",true)>
		            <cfoutput><script>alert("#SFLANG#");popClose(true);</script></cfoutput><CF_SFABORT>
	            </cfif> 
	            <!--- <cfset head_div = qgetheadDiv.position_id> --->
		      <!---   <cfoutput><script>console.log("yan : #approveryn#");</script></cfoutput> --->
	        	<cfquery name="local.getEmpDataPos" datasource="#REQUEST.SDSN#" >
	            	select a.emp_id,full_name,b.position_id,user_id as emp_uid,
	                c.pos_name_en as position,c.dept_id as dept_id,d.pos_name_en as org_unit ,
	                '' as form_no,'' as request_no,'' as approval_list,'' as approved_list,'' as reqemp,'' as requester,
	                '' as useratasan,'#REQUEST.sCOOKIE.USER.UID#' as loginid,'' as modified_by,'' as created_by,'#REQUEST.sCOOKIE.USER.empid#' as loginempid,
	                '' as evalkpi_status,'#approveryn#' as approverYN, '#head_div#' as head_div
	                from teomemppersonal a
	                left join teodempcompany b on a.emp_id=b.emp_id
	                left join teomposition c on b.position_id=c.position_id
	                left join teomposition d on c.dept_id=d.position_id
	                where a.emp_id =<cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	             </cfquery>
				
	             <cfquery name="local.qGetAtasan" datasource="#REQUEST.SDSN#">
	             	select distinct user_id from teodempcompany a
	             	left join teomemppersonal c on a.emp_id=c.emp_id
	               left join teomposition b on a.position_id=b.parent_id
	               where b.position_id = <cfqueryparam value="#getEmpDataPos.position_id#" cfsqltype="cf_sql_varchar">
	             </cfquery>
				 
	             <cfset getEmpDataPos.useratasan = qGetAtasan.user_id>
	             <cfquery name="local.getReq" datasource="#REQUEST.SDSN#">
	                select distinct modified_by,created_by,evalkpi_status
	                from TPMDPERFORMANCE_EVALKPI
	                where  orgunit_id =<cfqueryparam value="#qgetheadDiv.position_id#" cfsqltype="cf_sql_integer">
	                AND period_code=<cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
	             </cfquery>
	             
	             <cfif val(getReq.recordcount) gt 0>
	             	<cfset getEmpDataPos.modified_by = getReq.modified_by >
	             	<cfset getEmpDataPos.created_by = getReq.created_by >
	             	<cfset getEmpDataPos.evalkpi_status = getReq.evalkpi_status >
	             <cfelse>
	             	<cfset getEmpDataPos.modified_by = "" >
	             	<cfset getEmpDataPos.created_by = "" >
	             	<cfset getEmpDataPos.evalkpi_status = "" >
	             </cfif>
	        </cfif> 
	        
	        <cfreturn  getEmpDataPos >
	    </cffunction>
	    
<cffunction name="SaveEvalKPI">
	    	<cfparam name="sendtype" default="">
			<cfparam name="varcoid" default="#request.scookie.coid#">
			<cfparam name="varcocode" default="#request.scookie.cocode#">
			<cfparam name="sendtype" default="">
	        <cfset local.strckFormdata =FORM >
	        <cfset strckFormdata.evalkpi_status = sendtype>
	        <cfset strckFormdata.company_code = varcocode>
	        <cfset strckFormdata.orgunit_id = dept_id >
			<cfset LOCAL.objModel = CreateObject("component", "SMPerformanceEvalKPI") />
	        <cftransaction>
	            <cfquery name="local.qEvalKPI" datasource="#REQUEST.SDSN#">
	                SELECT distinct lib_code from TPMDPERFORMANCE_EVALKPI
	                WHERE 
	                period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
	                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                and iscategory= 'N'
	            </cfquery>
	           
	            <cfif qEvalKPI.recordcount>
	                <cfloop query="qEvalKPI">
	                    <cfset strckFormdata.lib_code = qEvalKPI.lib_code>
	                    <cfset strckFormdata.achievement = FORM["org_achievement_#qEvalKPI.lib_code#"]>
	                    <cfset strckFormdata.score = FORM["org_score_#qEvalKPI.lib_code#"]>
	                    <cfquery name="local.qCheckEvalKPILib" datasource="#REQUEST.SDSN#">
	                        select distinct lib_code from TPMDPERFORMANCE_EVALKPI
	                        where period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
			                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                        and lib_code = <cfqueryparam value="#strckFormdata.lib_code#" cfsqltype="cf_sql_varchar">
	                    </cfquery>
	                
	                    <cfif qCheckEvalKPILib.recordcount>
	                        <cfset local.retvar = objModel.update(strckFormdata)>
	                    <cfelse>
	                        <cfset local.retvar = objModel.insert(strckFormdata)>
	                    </cfif>    
	                </cfloop>
	                <cfquery name="local.qUpdateevalKPIStatusAll" datasource="#REQUEST.SDSN#">
	                    Update TPMDPERFORMANCE_EVALKPI
	                    set evalkpi_status = <cfqueryparam value="#strckFormdata.evalkpi_status#" cfsqltype="cf_sql_varchar">
	                    where 
	                    period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
		                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                </cfquery>
	            <cfelse>
					 <cfquery name="local.qGetPlanForm" datasource="#REQUEST.SDSN#">
					 select form_no from TPMDPERFORMANCE_PLANKPI
					 where  period_code=<cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
		                AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
					 </cfquery>
	                <cfinvoke component="SFPerformanceEvaluation" method="getEmpFormData" empid="#emp_id#" periodcode="#period_code#" refdate="#reference_date#" compcode="ORGKPI" reviewerempid="#request.scookie.user.empid#" varcoid="#request.scookie.coid#" formno ="#qGetPlanForm.form_no#" varcocode="#request.scookie.cocode#" returnvariable="Local.qEmpFormData">
	                <cfloop query="qEmpFormData">
	                    <cfset strckFormdata.lib_code = qEmpFormData.LIBCODE>
	                    <cfset strckFormdata.lib_name_en = qEmpFormData.LIBNAME>
	                    <cfset strckFormdata.lib_desc_en = qEmpFormData.LIB_DESC_EN>
	                    <cfset strckFormdata.iscategory = qEmpFormData.ISCATEGORY>
	                    <cfset strckFormdata.lib_depth= qEmpFormData.DEPTH>
	                    <cfset strckFormdata.weight= qEmpFormData.WEIGHT>
	                    <cfset strckFormdata.target= qEmpFormData.TARGET>
	                    <cfset strckFormdata.achievement_type= qEmpFormData.ACHSCORETYPE>
	                    <cfquery name="local.qGetParentLib" datasource="#REQUEST.SDSN#">
	                        select <cfif request.dbdriver EQ "MSSQL">TOP 1</cfif> lib_code,parent_path,parent_code,lib_order,lookup_code from TPMDPERFORMANCE_PLANKPI
	                        WHERE lib_code =<cfqueryparam value="#qEmpFormData.LIBCODE#" cfsqltype="cf_sql_varchar">
	                        	AND orgunit_id = <cfqueryparam value="#strckFormdata.orgunit_id#" cfsqltype="cf_sql_integer">
	                            AND company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar">
	                            AND period_code = <cfqueryparam value="#strckFormdata.period_code#" cfsqltype="cf_sql_varchar">
	                            <cfif request.dbdriver EQ "MYSQL">LIMIT 1</cfif>
	                            <cfif request.dbdriver EQ "ORACLE">AND ROWNUM = 1</cfif>
	                    </cfquery>
	                    <cfif qGetParentLib.recordcount>
	                        <cfset strckFormdata.parent_code= qGetParentLib.parent_code>
	                        <cfset strckFormdata.parent_path= qGetParentLib.parent_path>
	                        <cfset strckFormdata.lib_order= qGetParentLib.lib_order>
	                        <cfset strckFormdata.lookup_code = qGetParentLib.lookup_code>
	                    </cfif>    
	                    <cfif qEmpFormData.ISCATEGORY eq 'N'>
	                        <cfset strckFormdata.achievement = FORM["org_achievement_#libcode#"]>
	                        <cfset strckFormdata.score = FORM["org_score_#libcode#"]>
	                 	</cfif>
	                   <cfset local.retvar = objModel.insert(strckFormdata)>
	                </cfloop>
	            </cfif>
			</cftransaction>
			
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSSuccessfully Save Data",true)>
	        <cfoutput>
	            <script>
	                alert("#SFLANG#");
	                parent.popClose(true);
	                parent.refreshPage();
	            </script>
	        </cfoutput>    
	    </cffunction>
	  		
	  	<cffunction name="GetDataEvalD">
			<cfargument name="periodcode" default="">
			<cfargument name="formno" default="">
			<cfargument name="refdate" default="#Now()#">
			<cfargument name="parseEmp" default="">
			<cfargument name="lpr" default="">
			<cfargument name="empid" default="">
			<cfargument name="compcode" default="">
			<cfargument name="varcocode" default="#request.scookie.cocode#" required="No">
			<cfquery name="local.qGetDataEvalD" datasource="#request.sdsn#">
				SELECT a.form_no, a.reviewer_empid, a.lib_code, a.company_code, a.notes, a.achievement, a.score, b.head_status
				FROM TPMDPERFORMANCE_EVALD a LEFT JOIN TPMDPERFORMANCE_EVALH b 
				ON a.form_no = b.form_no AND a.reviewer_empid = b.reviewer_empid 	
				WHERE  a.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar"> 
				AND a.company_code = <cfqueryparam value="#request.scookie.cocode#" cfsqltype="cf_sql_varchar"> 
				<cfif varcocode eq request.scookie.cocode>
					AND a.reviewer_empid = <cfqueryparam value="#empid#" list="yes" cfsqltype="cf_sql_varchar"> 
				</cfif>
				AND a.lib_code = <cfqueryparam value="#libcode#" cfsqltype="cf_sql_varchar">
				AND b.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
				<cfif ucase(compcode) eq "appraisal">
				AND a.lib_type = 'appraisal'
				<cfelseif ucase(compcode) eq "PERSKPI">
				AND a.lib_type = 'PERSKPI'
				<cfelseif ucase(compcode) eq "ORGKPI">
				AND a.lib_type = 'ORGKPI'
				<cfelseif ucase(compcode) eq "ORGKPI">
				AND a.lib_type = 'COMPETENCY'
				</cfif>
			</cfquery>

			<cfreturn qGetDataEvalD>
		</cffunction>
		
	
		<cffunction name="getPlanGradeStat"> <!---ENC50616-80432--->
	    	<cfargument name="empid" default="">
	    	<cfargument name="formno" default="">
	    	<cfargument name= "reqno" default="">
	        <cfquery name="local.qGetPlanGradeStat" datasource="#request.sdsn#">
	            SELECT distinct EH.reviewee_grade,EH.reviewee_employcode, GRD.grade_name AS empgrade
	            , ES.employmentstatus_name_#request.scookie.lang# emp_status
	            FROM TPMDPERFORMANCE_EVALH EH
	            LEFT JOIN TEOMJOBGRADE GRD ON GRD.grade_code = EH.reviewee_grade 
	            LEFT JOIN TEOMEMPLOYMENTSTATUS ES ON EH.reviewee_employcode = ES.employmentstatus_code
	            WHERE EH.reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
	            AND EH.form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
	            AND EH.request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
	        </cfquery>
	    	<cfreturn qGetPlanGradeStat>
	    </cffunction>
	    
	    
	    <!---ENC50618-81669--->
		<cffunction name="FilterEvalFormEmployeeFullyApprove">
    		<cfparam name="period_code" default="">
    		<cfparam name="grade_order" default="">
    		<cfparam name="search" default="">
    		<cfparam name="nrow" default="50">
    	
    		<cfparam name="isformstatus" default="N">
    		<cfif NOT isdefined("hdnSelectedformstatus")>
    		    <cfset isformstatus = 'Y'>
    		</cfif>
    		<cfset rowfilter = REQUEST.CONFIG.ROWPERFILTER>
    		
    		<cfparam name="hdnSelectedformstatus" default="">
    		<!--- <cfset isformstatus=true> TCK1018-81902 --->
    		<cfset nrow = rowfilter>
    
    		<cfif val(nrow) eq "0">
    			<cfset local.nrow="50">
    		</cfif>
    	
    		<cfset LOCAL.searchText=trim(search)>
    		<cfset LOCAL.count = 1/>
    
    		<!--- filter employee  [ ENC50917-81121 ]--->
    		<cfparam name="ftpass" default="">
    		<cfset local.lstparams="alldept,work_loc,work_status,cost_center,job_status,job_grade,emp_pos,emp_status,gender,marital,religion,hdnfaoempnolist">
    		<cfif ftpass neq "" AND IsJSON(ftpass)>
    			<cfset local.params=DeserializeJSON(ftpass)>
    			<Cfset local.iidx = "">
    			<cfloop list="#lstparams#" index="iidx">
    				<cfif StructKeyExists(params,iidx)>
    					<cfparam name="#iidx#" default="#params[iidx]#">
    				<cfelse>
    					<cfparam name="#iidx#" default="">
    				</cfif>
    			</cfloop>
    		</cfif>
    
    		<cfif ftpass neq "" AND IsJSON(ftpass) AND isdefined("alldept") AND alldept eq "false">
    			<cfif request.dbdriver eq 'MYSQL'><!--- untuk inclusive --->
    				<cfset LOCAL.cond_dept0=replace(params.dept,",",",%' OR CONCAT(',',e.parent_path,',') LIKE '%,","All")>
    				<cfset LOCAL.cond_dept=PreserveSingleQuotes(LOCAL.cond_dept0)>
    			<cfelse>
    				<cfset LOCAL.cond_dept0=replace(params.dept,",",",%' OR ','#REQUEST.DBSTRCONCAT#e.parent_path#REQUEST.DBSTRCONCAT#',' LIKE '%,","All")>
    				<cfset LOCAL.cond_dept=PreserveSingleQuotes(LOCAL.cond_dept0)>
    			</cfif>
    		<cfelse>
    			<cfset LOCAL.cond_dept="">
    		</cfif>
    		<cfset LOCAL.lsGender="Female,Male">
    		<cfset LOCAL.lsMarital="Single,Married,Widow,Widower,Divorce">
    		<cfset LOCAL.EmpLANG=Application.SFParser.TransMLang(listAppend(lsMarital,lsGender),false,",")>
    		<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
    		<!--- <cfset LOCAL.qListEmpFullyAppr = qGetListEvalFullyApproveAndClosed(period_code=period_code)> --->
    		
			<cfquery name="local.qData" datasource="#request.sdsn#">
				SELECT distinct a.emp_id, full_name, full_name AS emp_name, b.emp_no
				<cfif ReturnVarCheckCompParam eq false OR request.scookie.cocode eq "issid"> 
				  ,EH.form_no 
				<cfelse>
				  ,CASE WHEN EH.form_no IS NOT NULL THEN EH.form_no ELSE EGEN.form_no END form_no
				</cfif>
				  ,TCLTREQUEST.req_no
				 ,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name, TPMMPERIOD.reference_date
				FROM TEOMEMPPERSONAL a
				LEFT JOIN TEODEMPCOMPANY b ON a.emp_id = b.emp_id
				    AND b.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
				<!--- LEFT JOIN TCLRGroupMember GM on GM.emp_id = b.emp_id --->
				<!--- LEFT JOIN TEODEMPLOYMENTHISTORY d ON a.emp_id = d.emp_id --->
				LEFT JOIN TEOMPOSITION e ON e.position_id = b.position_id AND e.company_id = b.company_id
				LEFT JOIN TEODEmppersonal f ON f.emp_id = b.emp_id 
				LEFT JOIN 
				<cfif ReturnVarCheckCompParam eq false OR request.scookie.cocode eq "issid">
					TPMDPERFORMANCE_EVALH EH ON EH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
				    AND EH.reviewee_empid = b.emp_id 
					AND EH.reviewee_posid = b.position_id
						<cfif isformstatus EQ 'N' AND (ListFindNoCase(hdnSelectedformstatus,'3') OR ListFindNoCase(hdnSelectedformstatus,'9') )>
							AND EH.isfinal = 1
						</cfif>
					AND EH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
				<cfelse>
					TPMDPERFORMANCE_EVALGEN EGEN ON EGEN.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
				    AND EGEN.reviewee_empid = b.emp_id 
					AND EGEN.reviewee_posid = b.position_id
					AND EGEN.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
					
					LEFT JOIN TPMDPERFORMANCE_EVALH EH ON EH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
				    AND EH.reviewee_empid = b.emp_id 
					AND EH.reviewee_posid = b.position_id
						<cfif isformstatus EQ 'N' AND (ListFindNoCase(hdnSelectedformstatus,'3') OR ListFindNoCase(hdnSelectedformstatus,'9') )>
							AND EH.isfinal = 1
						</cfif>
					AND EH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
				</cfif>
                LEFT JOIN TCLTREQUEST ON 
				 <cfif ReturnVarCheckCompParam eq false OR request.scookie.cocode eq "issid">TCLTREQUEST.req_no = EH.request_no<cfelse>(TCLTREQUEST.req_no = EH.request_no OR TCLTREQUEST.req_no = EGEN.req_no )</cfif>
               	
                LEFT JOIN TPMMPERIOD ON 
			    <cfif ReturnVarCheckCompParam eq false OR request.scookie.cocode eq "issid">
                    TPMMPERIOD.period_code = EH.period_code
                <cfelse>
                    (TPMMPERIOD.period_code = EH.period_code OR TPMMPERIOD.period_code = EGEN.period_code )
                </cfif>
                <!---
                LEFT JOIN TPMDPERFORMANCE_FINAL
                    ON TPMDPERFORMANCE_FINAL.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
                    AND TPMDPERFORMANCE_FINAL.reviewee_empid = a.emp_id
                --->
				WHERE b.company_id = #REQUEST.SCookie.COID#
				AND (TCLTREQUEST.req_no IS NOT NULL )
			    <!--- AND a.emp_id IN (<cfqueryparam value="#ValueList(qListEmpFullyAppr.emp_id)#" cfsqltype="CF_SQL_VARCHAR" list="Yes">) --->
			    <cfif ReturnVarCheckCompParam eq false OR request.scookie.cocode eq "issid"> 
				    AND EH.form_no <> ''
					AND EH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                    AND EH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
				<cfelse>
				    AND (EH.form_no <> '' OR EGEN.form_no <> '')
					AND (EH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
					OR EGEN.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">)
                    AND (EH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
                    OR EGEN.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">)
				</cfif>
                  AND b.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">

				<cfif isformstatus EQ 'Y'>
            	    AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                <cfelse>
                	AND TCLTREQUEST.status IN (<cfqueryparam value="#hdnSelectedformstatus NEQ '' ? hdnSelectedformstatus : '-' #" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
                	#ReturnVarCheckCompParam eq false AND ( ListFindNoCase(hdnSelectedformstatus,'3') OR ListFindNoCase(hdnSelectedformstatus,'9') ) ? 'AND EH.isfinal = 1' : ''#
                </cfif>
	           
				<cfif grade_order neq "">
					<cfset grade_order = replace(grade_order,",","','","ALL")/>
					AND b.grade_code IN ('#grade_order#')
				</cfif>

				<cfif len(searchText)>
					AND
					(
						a.Full_Name LIKE <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
						OR b.emp_no Like <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
						OR EH.form_no LIKE <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
						<cfif ReturnVarCheckCompParam eq true AND request.scookie.cocode neq "issid">
						OR EGEN.form_no LIKE <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
						</cfif>
						OR TCLTREQUEST.req_no LIKE <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
					)
				</cfif>

				<cfif ftpass neq "" AND IsJSON(ftpass)>
					<cfif isdefined("alldept") AND alldept eq "false"> 
						AND
						<cfif params.inclusive eq "false">
							<cfset local.where_dept="(e.parent_id = " & replace(params.dept,","," OR e.parent_id = ","All") & " OR e.dept_id = " & replace(params.dept,","," OR e.dept_id = ","All") & ")">
							#where_dept#					   
						<cfelse>
							<cfif request.dbdriver eq 'MYSQL'>
								(CONCAT(',',e.parent_path,',') LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							<cfelse>
								(','#REQUEST.DBSTRCONCAT#e.parent_path#REQUEST.DBSTRCONCAT#',' LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							</cfif>
						</cfif>
						
					</cfif>
					<cfif isdefined("work_loc") AND len(work_loc)>
						AND b.work_location_code in (<cfqueryparam value="#work_loc#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(work_status) and work_status eq "1">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date >= getdate() OR b.end_date IS NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date >= NOW() OR b.end_date IS NULL)
						 </cfif>
					<cfelseif len(work_status) and work_status eq "0">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date < getdate() AND b.end_date IS NOT NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date < NOW() AND b.end_date IS NOT NULL)
						 </cfif>
					</cfif>
					<cfif isdefined("cost_center") AND len(cost_center)>
						AND b.cost_code IN (<cfqueryparam value="#cost_center#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_status") AND len(job_status)>
						AND b.job_status_code IN (<cfqueryparam value="#job_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_grade") AND len(job_grade)>
						AND b.grade_code IN (<cfqueryparam value="#job_grade#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_pos)>
						AND b.position_id IN (<cfqueryparam value="#emp_pos#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_status)>
						AND b.employ_code IN (<cfqueryparam value="#emp_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!---Personal_Information--->
					<cfif len(gender) and gender neq "2">
						#APPLICATION.SFUtil.getLookupQueryPart("gender",gender,"0=Female|1=Male",0,"AND")#
					</cfif>
					<cfif len(marital)>
						AND f.maritalstatus = <cfqueryparam value="#marital#" cfsqltype="CF_SQL_INTEGER">
					</cfif>
					<cfif len(religion)>
						AND f.religion_code IN (<cfqueryparam value="#religion#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!--- Filter Employeeno --->
					<cfif len(trim(hdnfaoempnolist))>
                        AND (#Application.SFUtil.CutList(ListQualify(hdnfaoempnolist,"'")," b.emp_no IN  ","OR",2)#)
                    </cfif>
                    <!--- Filter Employeeno --->
                <cfelse>
                    <!--- default employee aktif --->
					<cfif request.dbdriver eq "MSSQL">
					 AND (b.end_date >= getdate() OR b.end_date IS NULL)
					 <cfelseif request.dbdriver eq "MYSQL">
					 AND (b.end_date >= NOW() OR b.end_date IS NULL)
					 </cfif>
                    <!--- default employee aktif --->
				</cfif>
				<!---Filter:Employee_Information  [ ENC50917-81121 ]--->

				ORDER BY full_name	
			</cfquery>
			

			<cfquery name="LOCAL.getEmpEvalUpload" datasource="#request.sdsn#">
			    SELECT distinct 
			        a.emp_id, 
			        a.full_name, 
			        a.full_name AS emp_name, 
			        b.emp_no,
                    TPMDPERFORMANCE_FINAL.form_no,
                    '' req_no,
                    TPMMPERIOD.period_name_#request.scookie.lang# AS period_name, TPMMPERIOD.reference_date
                FROM TPMDPERFORMANCE_FINAL
                INNER JOIN TEOMEMPPERSONAL a
                    ON a.emp_id = TPMDPERFORMANCE_FINAL.reviewee_empid
				LEFT JOIN TEODEMPCOMPANY b ON a.emp_id = b.emp_id
				    AND b.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
				LEFT JOIN TEOMPOSITION e ON e.position_id = b.position_id AND e.company_id = b.company_id
				LEFT JOIN TEODEmppersonal f ON f.emp_id = b.emp_id 
                LEFT JOIN TPMMPERIOD ON 
                    TPMMPERIOD.period_code = TPMDPERFORMANCE_FINAL.period_code
                    AND TPMMPERIOD.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                WHERE TPMDPERFORMANCE_FINAL.is_upload = 'Y'
                    AND TPMDPERFORMANCE_FINAL.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
				
				<cfif len(searchText)>
					AND
					(
						a.Full_Name LIKE <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
						OR b.emp_no Like <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
						OR TPMDPERFORMANCE_FINAL.form_no LIKE <cfqueryparam value="%#searchText#%" cfsqltype="cf_sql_varchar">
					)
				</cfif>

				<cfif ftpass neq "" AND IsJSON(ftpass)>
					<cfif isdefined("alldept") AND alldept eq "false"> 
						AND
						<cfif params.inclusive eq "false">
							<cfset local.where_dept="(e.parent_id = " & replace(params.dept,","," OR e.parent_id = ","All") & " OR e.dept_id = " & replace(params.dept,","," OR e.dept_id = ","All") & ")">
							#where_dept#					   
						<cfelse>
							<cfif request.dbdriver eq 'MYSQL'>
								(CONCAT(',',e.parent_path,',') LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							<cfelse>
								(','#REQUEST.DBSTRCONCAT#e.parent_path#REQUEST.DBSTRCONCAT#',' LIKE '%,#PreserveSingleQuotes(LOCAL.cond_dept)#,%')
							</cfif>
						</cfif>
						
					</cfif>
					<cfif isdefined("work_loc") AND len(work_loc)>
						AND b.work_location_code in (<cfqueryparam value="#work_loc#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(work_status) and work_status eq "1">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date >= getdate() OR b.end_date IS NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date >= NOW() OR b.end_date IS NULL)
						 </cfif>
					<cfelseif len(work_status) and work_status eq "0">
						<cfif request.dbdriver eq "MSSQL">
						 AND (b.end_date < getdate() AND b.end_date IS NOT NULL)
						 <cfelseif request.dbdriver eq "MYSQL">
						 AND (b.end_date < NOW() AND b.end_date IS NOT NULL)
						 </cfif>
					</cfif>
					<cfif isdefined("cost_center") AND len(cost_center)>
						AND b.cost_code IN (<cfqueryparam value="#cost_center#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_status") AND len(job_status)>
						AND b.job_status_code IN (<cfqueryparam value="#job_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif isdefined("job_grade") AND len(job_grade)>
						AND b.grade_code IN (<cfqueryparam value="#job_grade#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_pos)>
						AND b.position_id IN (<cfqueryparam value="#emp_pos#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<cfif len(emp_status)>
						AND b.employ_code IN (<cfqueryparam value="#emp_status#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!---Personal_Information--->
					<cfif len(gender) and gender neq "2">
						#APPLICATION.SFUtil.getLookupQueryPart("gender",gender,"0=Female|1=Male",0,"AND")#
					</cfif>
					<cfif len(marital)>
						AND f.maritalstatus = <cfqueryparam value="#marital#" cfsqltype="CF_SQL_INTEGER">
					</cfif>
					<cfif len(religion)>
						AND f.religion_code IN (<cfqueryparam value="#religion#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
					</cfif>
					<!--- Filter Employeeno --->
					<cfif len(trim(hdnfaoempnolist))>
                        AND (#Application.SFUtil.CutList(ListQualify(hdnfaoempnolist,"'")," b.emp_no IN  ","OR",2)#)
                    </cfif>
                    <!--- Filter Employeeno --->
                </cfif>
			</cfquery>
	
	        <cfquery name="LOCAL.qData0" dbtype="query">
	            SELECT *  FROM qData
	            UNION
	            SELECT *  FROM getEmpEvalUpload
	        </cfquery>
	
	        <cfset qData = qData0>
			
			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSEmployee",true,"+")>
			<cfset LOCAL.vResult="">
			<cfloop query="qData">
			    <cfset vResult=vResult & "
				arrEntryList[#currentrow-1#]=""#JSStringFormat(form_no & "=" & emp_name & " [#emp_no#]")#"";">
			</cfloop>
			<cfoutput>
			    <cfset LOCAL.SFLANG1=Application.SFParser.TransMLang("NotAvailable",true,"+")>
				<script>
				    arrEntryList=new Array();
					document.getElementById('lbl_inp_form_no').innerHTML  = '#SFLANG# (#qData.recordcount#) <span class=\"required\">*</span>';
					$('[id=tr_inp_period_date] > [id=tdb_1]').html('#SFLANG1#');
    				<cfif len(vResult)>
    					#vResult#
    					document.getElementById('unselinp_form_no').value = '#valuelist(qData.emp_id)#'; 
    				    $('[id=tr_inp_period_date] > [id=tdb_1]').html('#DateFormat(qData.reference_date,REQUEST.config.DATE_OUTPUT_FORMAT)#');
    				</cfif>
			    </script>
			</cfoutput>
		</cffunction>
	    
	    	<cffunction name="qGetListEvalFullyDelApproveAndClosed">
				<cfparam name="period_code" default="">
				<cfparam name="lst_emp_id" default="">
				<cfparam name="is_emp_defined" default="N">
				<cfparam name="by_form_no" default="N">
				<cfparam name="form_no" default="">
			
				<cfparam name="allstatus" default="false"><!---TCK1018-81902--->
				 <cfset LOCAL.dataQuery=Application.SFSec.DAuthSQL("0,1,2,3","hrm.performance","TEODEMPCOMPANY.emp_id")>
			
			 <cfquery name="local.qListEmpFullyApprClosed" datasource="#request.sdsn#">
	            SELECT 
	            	DISTINCT
	            	TPMDPERFORMANCE_EVALH.form_no, 
	            	TPMDPERFORMANCE_EVALH.request_no, 
	            	TPMDPERFORMANCE_EVALH.period_code,
	            	TPMDPERFORMANCE_EVALH.reviewee_empid,
	            	TPMDPERFORMANCE_EVALH.reference_date
	            	
	            	,TCLTREQUEST.reqemp
	            	,TEOMEMPPERSONAL.full_name
	            	,TEODEMPCOMPANY.emp_no
	            	,TEODEMPCOMPANY.emp_id
	            	,TEOMPOSITION.pos_name_#request.scookie.lang# AS pos_name
	            	,ORG.pos_name_#request.scookie.lang# AS orgunit
	            	,TEOMJOBGRADE.grade_name
	            	
	            	,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
	            	
	            FROM TPMDPERFORMANCE_EVALH
	            
	            LEFT JOIN TCLTREQUEST
	            	ON TCLTREQUEST.req_no = TPMDPERFORMANCE_EVALH.request_no
	            	AND TCLTREQUEST.req_no IS NOT NULL
	            
	            LEFT JOIN TEOMEMPPERSONAL
	            	ON TEOMEMPPERSONAL.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
	            	
	            LEFT JOIN TEODEMPCOMPANY ON TEODEMPCOMPANY.emp_id = TPMDPERFORMANCE_EVALH.reviewee_empid
	                AND TEODEMPCOMPANY.position_id = TPMDPERFORMANCE_EVALH.reviewee_posid
	                
	            LEFT JOIN TEOMPOSITION ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id 

	            LEFT JOIN TEOMPOSITION ORG  ON ORG.position_id = TEOMPOSITION.dept_id
	                
	            LEFT JOIN TPMMPERIOD ON TPMMPERIOD.period_code = TPMDPERFORMANCE_EVALH.period_code 
	                
	                    
	            LEFT JOIN TEOMJOBGRADE 
	                ON TEODEMPCOMPANY.grade_code = TEOMJOBGRADE.grade_code 
	                AND TEODEMPCOMPANY.company_id = TEOMJOBGRADE.company_id 
	                    	
	            WHERE TCLTREQUEST.req_no IS NOT NULL
	                AND TPMDPERFORMANCE_EVALH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
	                AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
					<cfif REQUEST.SCookie.User.UTYPE neq "9">
						AND (
						<cfif len(trim(dataQuery.rowcl))> #preserveSingleQuotes(dataQuery.rowcl)#</cfif> 
						)
					</cfif>
                    <cfif allstatus EQ true>
                	    AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                    <cfelse>
    	            	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
    	            	AND TPMDPERFORMANCE_EVALH.isfinal = 1
                    </cfif>
	            	
	            	<cfif by_form_no EQ 'Y'>
	            	    AND TPMDPERFORMANCE_EVALH.form_no IN (<cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar" list="yes">)
	            	<cfelse>
	            	    AND TPMDPERFORMANCE_EVALH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
	            	</cfif>
	            	
	            	<cfif is_emp_defined eq 'Y'>
	            	    AND TPMDPERFORMANCE_EVALH.reviewee_empid IN (<cfqueryparam value="#lst_emp_id#" cfsqltype="cf_sql_varchar" list="yes">)
	            	</cfif>
	            	
	            ORDER BY full_name
			</cfquery>
			
			<cfreturn qListEmpFullyApprClosed>
		</cffunction>
		
	    
		<cffunction name="FilterEvalFormFullyApprove">
			<cfparam name="period_code" default="">
			<cfparam name="search" default="">
			<cfparam name="nrow" default="50">
			
			<cfif val(nrow) eq "0">
				<cfset local.nrow="50">
			</cfif>
			<cfset LOCAL.searchText=trim(search)>
			<cfset LOCAL.count = 1/>

			<!--- Get emp_id fully approved perf plan--->
			<cfset LOCAL.qListEmpFullyAppr = qGetListEvalFullyApproveAndClosed(period_code=period_code)>
			<!--- Get emp_id fully approved perf plan--->
	        <cfquery name="LOCAL.qData" dbtype="query">
	            SELECT * FROM qListEmpFullyAppr
	            WHERE 1=1
				<cfif len(searchText)>
					AND
					(
						form_no LIKE '%#searchText#%'
					)
				</cfif>
	        </cfquery>
	        

			<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("FDFormNo",true,"+")>
			<cfset LOCAL.vResult="">
			<cfloop query="qData">
			    <cfset vResult=vResult & "
				arrEntryList[#currentrow-1#]=""#JSStringFormat(form_no & "=" & form_no & "")#"";">
			</cfloop>
			<cfoutput>
			   
				<script>
				    arrEntryList=new Array();
					document.getElementById('lbl_inp_form_no').innerHTML  = '#SFLANG# (#qData.recordcount#) <span class=\"required\">*</span>';
					<cfif len(vResult)>
						#vResult#
						document.getElementById('unselinp_form_no').value = '#valuelist(qData.form_no)#'; 
					</cfif>
			    </script>
			</cfoutput>
		</cffunction>
	    
		<cffunction name="qGetListEvalFullyApproveAndClosed">
			<cfparam name="period_code" default="">
			<cfparam name="lst_emp_id" default="">
			<cfparam name="is_emp_defined" default="N">
			<cfparam name="by_form_no" default="N">
			<cfparam name="form_no" default="">
			
			<cfparam name="allstatus" default="false"><!---TCK1018-81902--->
			<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			
			<!---Get emp uploaded--->
		    <cfquery name="LOCAL.getEmpEvalUpload" datasource="#request.sdsn#">
			    SELECT distinct 
                    TPMDPERFORMANCE_FINAL.form_no,
                    '' request_no,
                    '' req_no,
			        a.emp_id reviewee_empid, 
                    TPMMPERIOD.period_code, 
                    TPMMPERIOD.reference_date,
                    
			        a.emp_id reqemp, 
			        a.full_name, 
			        b.emp_no,
			        a.emp_id, 
                    e.pos_name_#request.scookie.lang# AS pos_name,
                    ORG.pos_name_#request.scookie.lang# AS orgunit,
                    TEOMJOBGRADE.grade_name,
                    TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
                    
                FROM TPMDPERFORMANCE_FINAL
                INNER JOIN TEOMEMPPERSONAL a
                    ON a.emp_id = TPMDPERFORMANCE_FINAL.reviewee_empid
				LEFT JOIN TEODEMPCOMPANY b ON a.emp_id = b.emp_id
				    AND b.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
				LEFT JOIN TEOMPOSITION e ON e.position_id = b.position_id AND e.company_id = b.company_id
	            LEFT JOIN TEOMPOSITION ORG 
	                ON ORG.position_id = e.dept_id
	            LEFT JOIN TEOMJOBGRADE 
	                ON b.grade_code = TEOMJOBGRADE.grade_code 
	                AND b.company_id = TEOMJOBGRADE.company_id 
				LEFT JOIN TEODEmppersonal f ON f.emp_id = b.emp_id 
                LEFT JOIN TPMMPERIOD ON 
                    TPMMPERIOD.period_code = TPMDPERFORMANCE_FINAL.period_code
                    AND TPMMPERIOD.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                WHERE TPMDPERFORMANCE_FINAL.is_upload = 'Y'
                    AND TPMDPERFORMANCE_FINAL.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
				
	            	<cfif by_form_no EQ 'Y'>
	            	    AND TPMDPERFORMANCE_FINAL.form_no IN (<cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar" list="yes">)
	            	<cfelse>
	            	    AND TPMDPERFORMANCE_FINAL.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
	            	</cfif>
			</cfquery>
			<!---Get emp uploaded--->
			
			
			<!--- Get emp_id fully approved perf plan--->
			<cfquery name="local.qListEmpFullyApprClosedNotPregen" datasource="#request.sdsn#">
	            SELECT 
	            	DISTINCT
						EH.form_no, 
						EH.request_no, 
						EH.request_no req_no, 
						EH.reviewee_empid,
					TPMMPERIOD.period_code,
	            	TPMMPERIOD.reference_date
	            	
	            	,TCLTREQUEST.reqemp
	            	,TEOMEMPPERSONAL.full_name
	            	,TEODEMPCOMPANY.emp_no
	            	,TEODEMPCOMPANY.emp_id
	            	,TEOMPOSITION.pos_name_#request.scookie.lang# AS pos_name
	            	,ORG.pos_name_#request.scookie.lang# AS orgunit
	            	,TEOMJOBGRADE.grade_name
	            	
	            	,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
	            	
	            FROM TPMDPERFORMANCE_EVALH EH

	            LEFT JOIN TCLTREQUEST
					ON TCLTREQUEST.req_no = EH.request_no
	            	AND TCLTREQUEST.req_no IS NOT NULL
	            
	            LEFT JOIN TEOMEMPPERSONAL
	            	ON TEOMEMPPERSONAL.emp_id = EH.reviewee_empid
	            	
	            LEFT JOIN TEODEMPCOMPANY 
	                ON TEODEMPCOMPANY.emp_id  = EH.reviewee_empid
	                AND TEODEMPCOMPANY.position_id  = EH.reviewee_posid
	                
	            LEFT JOIN TEOMPOSITION
	                ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id 

	            LEFT JOIN TEOMPOSITION ORG 
	                ON ORG.position_id = TEOMPOSITION.dept_id
	                
	            LEFT JOIN TPMMPERIOD 
	                ON TPMMPERIOD.period_code = EH.period_code 
	                    
	            LEFT JOIN TEOMJOBGRADE 
	                ON TEODEMPCOMPANY.grade_code = TEOMJOBGRADE.grade_code 
	                AND TEODEMPCOMPANY.company_id = TEOMJOBGRADE.company_id 
	                    	
	            WHERE TCLTREQUEST.req_no IS NOT NULL
					AND EH.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
	                AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
	            
                    <cfif allstatus EQ true>
                	    AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                    <cfelse>
    	            	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
						<cfif ReturnVarCheckCompParam eq false>
						AND EH.isfinal = 1
						</cfif>
    	            	
                    </cfif>
	            	
	            	<cfif by_form_no EQ 'Y'>
	            	    AND EH.form_no IN (<cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar" list="yes">)
	            	<cfelse>
	            	    AND EH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
	            	</cfif>
	            	<cfif is_emp_defined eq 'Y'>
	            	    AND EH.reviewee_empid IN (<cfqueryparam value="#lst_emp_id#" cfsqltype="cf_sql_varchar" list="yes">)
	            	</cfif>
	            AND EH.form_no <> ''
	            ORDER BY TEOMEMPPERSONAL.full_name
			</cfquery>

		    <cfquery name="LOCAL.qData0" dbtype="query">
		        SELECT * FROM getEmpEvalUpload
		        UNION
		        SELECT * FROM qListEmpFullyApprClosedNotPregen
		    </cfquery>

			<cfif ReturnVarCheckCompParam EQ false>
			    <cfreturn qData0>
			</cfif>
			
			<cfquery name="local.qListEmpFullyApprClosedGenerated" datasource="#request.sdsn#">
	            SELECT 
	            	DISTINCT
						EH.form_no, 
						EH.req_no request_no, 
						EH.req_no, 
						EH.reviewee_empid,
					TPMMPERIOD.period_code,
	            	TPMMPERIOD.reference_date
	            	
	            	,TCLTREQUEST.reqemp
	            	,TEOMEMPPERSONAL.full_name
	            	,TEODEMPCOMPANY.emp_no
	            	,TEODEMPCOMPANY.emp_id
	            	,TEOMPOSITION.pos_name_#request.scookie.lang# AS pos_name
	            	,ORG.pos_name_#request.scookie.lang# AS orgunit
	            	,TEOMJOBGRADE.grade_name
	            	
	            	,TPMMPERIOD.period_name_#request.scookie.lang# AS period_name
	            	
	            FROM TPMDPERFORMANCE_EVALGEN EH
  
	            LEFT JOIN TCLTREQUEST
					ON TCLTREQUEST.req_no = EH.req_no
	            	AND TCLTREQUEST.req_no IS NOT NULL
	            
	            LEFT JOIN TEOMEMPPERSONAL
	            	ON TEOMEMPPERSONAL.emp_id = EH.reviewee_empid
	            	
	            LEFT JOIN TEODEMPCOMPANY 
	                ON TEODEMPCOMPANY.emp_id  = EH.reviewee_empid
	                AND TEODEMPCOMPANY.position_id  = EH.reviewee_posid
	                
	            LEFT JOIN TEOMPOSITION
	                ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id 

	            LEFT JOIN TEOMPOSITION ORG 
	                ON ORG.position_id = TEOMPOSITION.dept_id
	                
	            LEFT JOIN TPMMPERIOD 
	                ON TPMMPERIOD.period_code = EH.period_code 
	                    
	            LEFT JOIN TEOMJOBGRADE 
	                ON TEODEMPCOMPANY.grade_code = TEOMJOBGRADE.grade_code 
	                AND TEODEMPCOMPANY.company_id = TEOMJOBGRADE.company_id 
	                    	
	            WHERE TCLTREQUEST.req_no IS NOT NULL
					AND EH.company_id= <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
	                AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
	            
                    <cfif allstatus EQ true>
                	    AND TCLTREQUEST.status <> 5 AND TCLTREQUEST.status <> 8 <!--- 5=Rejected,8=Cancelled. All status except Cancelled and reject --->
                    <cfelse>
    	            	AND (TCLTREQUEST.status = 3 OR TCLTREQUEST.status = 9) <!--- 3=Fully Approved, 9=Closed --->
                    </cfif>
	            	
	            	<cfif by_form_no EQ 'Y'>
	            	    AND EH.form_no IN (<cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar" list="yes">)
	            	<cfelse>
	            	    AND EH.period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar">
	            	</cfif>
	            	
	            	<cfif is_emp_defined eq 'Y'>
	            	    AND EH.reviewee_empid IN (<cfqueryparam value="#lst_emp_id#" cfsqltype="cf_sql_varchar" list="yes">)
	            	</cfif>
	            AND EH.form_no <> ''
	            ORDER BY TEOMEMPPERSONAL.full_name
			</cfquery>
			
	    	<cfquery name="LOCAL.qListEmpFullyApprClosed0" dbtype="query">
			    SELECT * FROM qListEmpFullyApprClosedNotPregen
			    UNION
			    SELECT * FROM qListEmpFullyApprClosedGenerated
			    UNION 
			    SELECT * FROM getEmpEvalUpload
			</cfquery>
			<cfquery name="LOCAL.qListEmpFullyApprClosed" dbtype="query">
			    SELECT distinct form_no, request_no, reviewee_empid,period_code,reference_date
	            ,reqemp,full_name,emp_no,emp_id,pos_name,orgunit,grade_name,period_name from qListEmpFullyApprClosed0
			</cfquery>
		
			<cfreturn qListEmpFullyApprClosed>
		</cffunction>
		
		<cffunction name="DeleteEvaluationForm">
		    <cfparam name="lstdelete" default="">
		    
		    <cfloop list="#lstdelete#" index="LOCAL.form_no">
				<!--- Delete all data from Evaluation --->
				<cfset LOCAL.retvarDelPerfEval = DeleteAllPerfEvalByFormNo(form_no=form_no)>
				<!--- Delete all data from Evaluation --->
				<!--- Delete all data from 360 --->
                
		    </cfloop>
		    
	        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSYou have successfully delete Performance Evaluation data",true)>
			<cfif retvarDelPerfEval eq false>
			    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Delete Performance Evaluation",true)>
			</cfif>
		    
			<cfoutput>
				<script>
					alert("#SFLANG#");
					this.reloadPage();
				</script>
			</cfoutput>
		</cffunction> 
		
		<cffunction name="DeleteDetailPerfEval">
		    <cfparam name="formno" default="">
		    
		    <cfset LOCAL.retvarDelPerfEval = DeleteAllPerfEvalByFormNo(form_no=formno)>
		    
	        <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSYou have successfully delete Performance Evaluation data",true)>
			<cfif retvarDelPerfEval eq false>
			    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed Delete Performance Evaluation",true)>
			</cfif>
			<cfoutput>
				<script>
					alert("#SFLANG#");
					top.popClose();
					if(top.opener){
						top.opener.reloadPage();
					}
				</script>
			</cfoutput>
		</cffunction>
	    <!---ENC50618-81669--->
		
		
		<cffunction name="GetReviewerListPerReviewee">
			<cfargument name="reviewee_empid" default="false">
			<cfargument name="period_code" default="false">
			<cfset appcode = "PERFORMANCE.EVALUATION">
			<cfset fixedLstApp = "">
			<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			<cfif ReturnVarCheckCompParam EQ false>
				<cfquery name="qGetDtTrans" datasource="#request.sdsn#">
					select approval_data  from tcltrequest where req_no in (select request_no from tpmdperformance_evalh where reviewee_empid = '#arguments.reviewee_empid#' 
					and period_code = '#arguments.period_code#' and company_code = '#REQUEST.SCOOKIE.COCODE#')
				</cfquery>
				<cfif qGetDtTrans.recordcount gt 0>
					<cfset local.objWDApproval=SFReqFormat(qGetDtTrans.approval_data,"R",[])>
				<cfelse>
					<cfset strctApproverData = objRequestApproval.Generate(appcode, arguments.reviewee_empid, arguments.reviewee_empid, "-") />
					<cfset local.objWDApproval = strctApproverData.WDAPPROVAL>
				</cfif>
				<cfset tempListSharedReviewer = "">
				<cfset fixedLstApp = arguments.reviewee_empid>
				 <cfloop index="idxLoop1" from="1" to="#ArrayLen(objWDApproval)#">
				 
					<cfset structLoop1 = objWDApproval[idxLoop1]>
					<cfset structLoop1Approver = objWDApproval[idxLoop1].approver>
					<cfif ArrayLen(structLoop1Approver) eq 1>
						<cfset structLoop2Approver = structLoop1Approver[1]>
						<cfset isiStructAppEmpID = structLoop2Approver[1].emp_id>
						<cfif ListFindNoCase(fixedLstApp,isiStructAppEmpID,",") eq 0>
							<cfset fixedLstApp = ListAppend(fixedLstApp,isiStructAppEmpID)>
						</cfif>
					<cfelse>
						<cfloop index="local.idxLoop2" from="1" to="#ArrayLen(structLoop1Approver)#">
							<cfset structLoop2Approver = structLoop1Approver[idxLoop2]>	
							<cfloop index="local.idxLoop3" from="1" to="#ArrayLen(structLoop2Approver)#">
								<cfset isiStructAppEmpID = structLoop2Approver[idxLoop3].emp_id>
								<cfif ListFindNoCase(tempListSharedReviewer,isiStructAppEmpID,"|") eq 0>
									<cfset tempListSharedReviewer = ListAppend(tempListSharedReviewer,isiStructAppEmpID,"|")>		
								</cfif>	
							</cfloop>
							<cfif ListFindNoCase(fixedLstApp,tempListSharedReviewer,",") eq 0 AND ListLen(tempListSharedReviewer,"|") gt 1>
								<cfset fixedLstApp  = ListAppend(fixedLstApp,tempListSharedReviewer,",")>
							</cfif> 
						</cfloop>
					</cfif>
				 
				 </cfloop>
			<cfelse>
				<cfquery name="local.qListAppAll" datasource="#request.sdsn#">
					select reviewer_empid,review_step from tpmdperformance_evalgen where reviewee_empid = '#arguments.reviewee_empid#' 
					and period_code = '#arguments.period_code#' and company_id = #REQUEST.SCOOKIE.COID#
					order by review_step 
				</cfquery>
				<cfquery name="local.qListAppAllReviewStep" datasource="#request.sdsn#">
					select distinct review_step from tpmdperformance_evalgen where reviewee_empid = '#arguments.reviewee_empid#' 
					and period_code = '#arguments.period_code#' and company_id = #REQUEST.SCOOKIE.COID#
					order by review_step 
				</cfquery>
				<cfif qListAppAll.recordcount gt 0>
					<cfloop query="qListAppAllReviewStep">
						<cfset tempFixedLstApp = "">
						<cfquery name="local.qListAppAllLocal" dbtype="query">
						 select reviewer_empid from qListAppAll where review_step = #qListAppAllReviewStep.review_step# order by review_step
						</cfquery>
						<cfif qListAppAllLocal.recordcount gt 0>
							<cfset tempFixedLstApp = ValueList(qListAppAllLocal.reviewer_empid,"|")>
						</cfif>
						<cfset fixedLstApp = ListAppend(fixedLstApp,tempFixedLstApp,",")>
					</cfloop>
				</cfif>
				
			</cfif>
			
			<cfreturn fixedLstApp>
		</cffunction>
		<cffunction name="getApproverStep">
			<cfargument name="reviewee_empid" default="false">
			<cfargument name="reviewer_empid" default="false">
			<cfargument name="period_code" default="false">
			<cfset rvwr_empstep = 0>
			<cfset tempGetRevwrLstPerRviewee = GetReviewerListPerReviewee(reviewee_empid=arguments.reviewee_empid,period_code=arguments.period_code)>
			<cfloop list="#tempGetRevwrLstPerRviewee#" index="idxRvwr" delimiters=",">
				<cfset rvwr_empstep  = rvwr_empstep + 1>
				<cfif ListLen(idxRvwr,"|") eq 1>
					<cfif arguments.reviewer_empid eq idxRvwr>
						<cfbreak>
					</cfif>
				<cfelseif ListLen(idxRvwr,"|") gt 1>
				    <cfset LOCAL.gotIdApprover = 0>
					<cfloop list="#idxRvwr#" index="idxRvwrShared" delimiters="|">
						<cfif arguments.reviewer_empid eq idxRvwrShared>
						    <cfset gotIdApprover = 1>
						</cfif>
					</cfloop>
					<cfif gotIdApprover EQ 1>
						<cfbreak>
					</cfif>
				</cfif>
			</cfloop>
			<cfreturn rvwr_empstep>
		</cffunction>
		
		
    	<!---- start : these functions are used in New Layout Performance Evaluation Form ---->
		<cffunction name="getDetailFormBasedOnLibCode">
			<cfargument name="formno" default="">
			<cfargument name="reqno" default="">
			<cfquery name="local.qDetailFrmPerReviewer" datasource="#request.sdsn#">
				SELECT TPMDPERFORMANCE_EVALH.head_status, lib_code libcode, TEOMEMPPERSONAL.full_name, weight, target, lib_name_#request.scookie.lang# libname, 
				notes, photo, gender, TPMDPERFORMANCE_EVALD.reviewer_empid,  lib_desc_#request.scookie.lang# libdesc, achievement_type, TGEMSCORE.score_desc
				,TPMDPERFORMANCE_EVALH.isfinal,TPMDPERFORMANCE_EVALH.review_step,TPMDPERFORMANCE_EVALD.reviewer_empid
				FROM TPMDPERFORMANCE_EVALD 
				INNER JOIN TPMDPERFORMANCE_EVALH ON TPMDPERFORMANCE_EVALD.form_no = TPMDPERFORMANCE_EVALH.form_no AND TPMDPERFORMANCE_EVALD.reviewer_empid = TPMDPERFORMANCE_EVALH.reviewer_empid
				INNER JOIN TEOMEMPPERSONAL ON TPMDPERFORMANCE_EVALD.reviewer_empid = TEOMEMPPERSONAL.emp_id
				INNER JOIN TGEMSCORE ON TGEMSCORE.score_code = TPMDPERFORMANCE_EVALD.achievement_type
				WHERE TPMDPERFORMANCE_EVALD.form_no = <cfqueryparam value="#arguments.formno#" cfsqltype="cf_sql_varchar">
				AND TPMDPERFORMANCE_EVALD.company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODe#" cfsqltype="cf_sql_varchar">
				AND TPMDPERFORMANCE_EVALH.request_no =  <cfqueryparam value="#arguments.reqno#" cfsqltype="cf_sql_varchar">
				ORDER BY TPMDPERFORMANCE_EVALH.review_step 
			</cfquery>
			<cfreturn qDetailFrmPerReviewer>
		</cffunction>
		<cffunction name="getSavedFormEvalH">
			<cfargument name="periodcode" default="">
			<cfargument name="reviewee_empid" default="">
			<cfquery name="local.qGetSavedFormEvalH" datasource="#request.sdsn#">
				select reviewer_empid, head_status,review_step , form_no, request_no, isfinal,lastreviewer_empid, modified_date, created_date,modified_by,reviewee_empid
				FROM tpmdperformance_evalh where 
				period_code= <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				and company_code= <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
				and reviewee_empid = <cfqueryparam value="#arguments.reviewee_empid#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetSavedFormEvalH>
		</cffunction>
		<cffunction name="getPeriodComponent">
			<cfargument name="periodcode" default="">
			<cfquery name="local.qGetPeriodInfo" datasource="#request.sdsn#">
				select component_code,weight, tpmmperiod.score_type,tpmmperiod.conclusion_lookup,TPMMLOOKUP.lookup_code is_usinglookup from tpmdperiodcomponent 
				inner join tpmmperiod ON 
				    tpmdperiodcomponent.period_code = tpmmperiod.period_code 
				    AND tpmdperiodcomponent.company_code = tpmmperiod.company_code
				LEFT JOIN TPMMLOOKUP  <!---alv TCK1912-0536137 New Layout--->
					ON TPMDPERIODCOMPONENT.lookup_code = TPMMLOOKUP.lookup_code
					AND TPMDPERIODCOMPONENT.period_code = TPMMLOOKUP.period_code
				where tpmdperiodcomponent.period_code= <cfqueryparam value="#arguments.periodcode#" cfsqltype="cf_sql_varchar">
				and tpmdperiodcomponent.company_code= <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfreturn qGetPeriodInfo>
		</cffunction>
		<cffunction name="SaveEvaluationForm">
			 <cfparam name="period_code" default="">
			 <cfparam name="reference_date" default="">
			 <cfparam name="request_no" default="">
			 <cfparam name="formno" default="">
			 <cfparam name="coid" default="">
			 <cfparam name="cocode" default="">
			 <cfparam name="planformno" default="">
			 <cfparam name="listPeriodComponentUsed" default="">
			 <cfparam name="reqformulaorder" default="">
			 <cfparam name="RevieweeAsApprover" default="">
			 <cfparam name="UserInReviewStep" default="">
			 <cfparam name="FullListAppr" default="">
			 <cfparam name="score" default="">
			 <cfparam name="conclusion" default="">
			 <cfparam name="requestfor" default="">
			 <cfparam name="orgKPIArray" default="">
			 <cfparam name="orgKPI_lib" default="">
			 <cfparam name="persKPIArray" default="">
			 <cfparam name="persKPI_lib" default="">
			 <cfparam name="appraisalArray" default="">
			 <cfparam name="appraisal_lib" default="">
			 <cfparam name="competencyArray" default="">
			 <cfparam name="competency_lib" default="">
			 <cfparam name="appraisal" default="">
			 <cfparam name="appraisal_weight" default="">
			 <cfparam name="appraisal_weighted" default="">
			 <cfparam name="appraisal_totallookup" default="">
			 <cfparam name="appraisal_totallookupSc" default="">
			 <cfparam name="competency" default="">
			 <cfparam name="competency_weight" default="">
			 <cfparam name="competency_weighted" default="">
			 <cfparam name="task" default="">
			 <cfparam name="task_weight" default="">
			 <cfparam name="task_weighted" default="">
			 <cfparam name="feedback" default="">
			 <cfparam name="feedback_weight" default="">
			 <cfparam name="feedback_weighted" default="">
			 <cfparam name="objectiveorg" default="">
			 <cfparam name="objectiveorg_weight" default="">
			 <cfparam name="objective_totallookupSc" default="">
			 <cfparam name="action" default=""> 
			 <cfparam name="sendtype" default=""> 
			 
			 <cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
			
			<cfif ReturnVarCheckCompParam EQ false>
			
				<cfif request_no eq "">
					  <cfset local.retvarsfbp = SUPER.Add(true,true,FORM) />  
				<cfelse>
					<!--- <cfset local.retvarsfbp = SUPER.Save(true,true,FORM) />  --function save SFBP ada proses generate kembali ketika hasil replace approver akan error return blank --->
					<cfset callSendToNext = SendToNext()>
					<cf_sfabort>
				</cfif>
				<cfif retvarsfbp.result>
					<cfquery name="local.qGetFormNo" datasource="#request.sdsn#">
						select form_no from tpmdperformance_evalh
						where period_code = <cfqueryparam value="#period_code#" cfsqltype="cf_sql_varchar"> 
						and company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
						and request_no =  <cfqueryparam value="#retvarsfbp.REQUESTNO#" cfsqltype="cf_sql_varchar">
					</cfquery>
					<cfscript>
						data = {"success"="1","request_no"="#retvarsfbp.REQUESTNO#","form_no"="#qGetFormNo.form_no#"};
					</cfscript>
					<cfoutput>
						#SerializeJSON(data)#
					</cfoutput>
				</cfif>
			
			<cfelseif ReturnVarCheckCompParam EQ true AND request_no neq "">   <!--- this is pregenerate mode , and request_no shouldn't null  ----->
			
				<cfset callSendToNext = SendToNext()>
			
			</cfif>
			 
			
		</cffunction>
		
		
		
		
		<cffunction name="SaveAdditionalNotes">
			 <cfparam name="request_no" default="">
			 <cfparam name="formno" default="">
			 <cfparam name="period_code" default="">
			 <cfparam name="evalnoterecords" default="">
			 <cfparam name="sendtype" default="0">
			 
			 <cfquery name="local.qCheckPosID" datasource="#request.sdsn#">
			 select position_id from teodempcompany where 
			 is_main=1 and company_id = #REQUEST.SCOOKIE.COID# and status=1
			 and emp_id = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar"> 
			 </cfquery>
			<cfquery name="local.qCheckNotes" datasource="#request.sdsn#">
				delete from TPMDPERFORMANCE_EVALNOTE where form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
				and reviewer_empid = <cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">
				and company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
			</cfquery>
			<cfloop from="1" to="#evalnoterecords#" index="local.idx">
				<cfset local.note_name = Evaluate("evalnotename_#idx#")>
				<cfset local.note_answer =  Evaluate("evalnote_#idx#")>
				<cfif qCheckPosID.recordcount gt 0 and Trim(note_answer) neq "">
					<cfquery name="local.qInsertAddNotes" datasource="#request.sdsn#">
						INSERT INTO TPMDPERFORMANCE_EVALNOTE (form_no,company_code,reviewer_empid,reviewer_posid,note_name,note_answer,note_order,created_by,created_date,modified_by,modified_date) 
						VALUES(
							<cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#qCheckPosID.position_id#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#note_name#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#note_answer#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#idx#" cfsqltype="cf_sql_integer">,
							<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
							<cfqueryparam value="#request.scookie.user.empid#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
						)				
					</cfquery>
				</cfif>
				
			</cfloop>
			
			<!---Untuk Revise--->
			<cfif sendtype EQ 'revise'>
			    <cfset Revise()>
				<cf_sfabort>
			</cfif>
			<!---/Untuk Revise--->
			
			<cfset callSendToNext = SendToNext()>
			<!---<cfscript>
				data = {"success"="1","request_no"="#request_no#","form_no"="#formno#"};
			</cfscript>
			<cfoutput>
				#SerializeJSON(data)#
			</cfoutput>---->
		</cffunction>
		<!---- end : these functions are used in New Layout Performance Evaluation Form ---->
		
		
		<!--- 360  ---->
		<cffunction name="checkanyquestion">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.checkanyquestion()>
		</cffunction>
		
		<cffunction name="listingquestion">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.listingquestion()>
		</cffunction>
		
		<!--- SAVE 360 ANSWER --->
		<cffunction name="saveanswer">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.saveanswer()>
		</cffunction>
		
	    <!---360Quest--->
		<cffunction name="filterEmployeeQuestion">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.filterEmployeeQuestion()>
		</cffunction>
		
    	<cffunction name="filterMemberEmployeeQuestion">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.filterMemberEmployeeQuestion()>
    	</cffunction>
		
		
		<cffunction name="ManageRater">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.ManageRater()>
		</cffunction>
		
		
		<cffunction name="ManageRaterSave">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.ManageRaterSave()>
		</cffunction>
		
		<!---Send email--->
		<cffunction name="sendEmailSetRaterBasedFlagEmail">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.sendEmailSetRaterBasedFlagEmail()>
		</cffunction>
		<!---Send email--->

		<cffunction name="sendEmailNoLongerAsRater">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.sendEmailNoLongerAsRater()>
		</cffunction>
		
		<cffunction name="getRaterListing">
    		<cfset LOCAL.Obj360Question = createobject("component","SF360Question")>
		    <cfreturn Obj360Question.getRaterListing()>
		</cffunction>
		<!--- End 360 --->
		
		<!---Untuk Notif--->
		<cffunction name="Add">
		    <cfset SUPER.Add(false,true,FORM)>
		    
		    <!---Get alloskip param--->
            <cfset LOCAL.allowskipCompParam = "Y">
            <cfset LOCAL.requireselfassessment = 1>
            <cfquery name="LOCAL.qCompParam" datasource="#request.sdsn#">
            	SELECT field_value, UPPER(field_code) field_code from tclcappcompany where UPPER(field_code) IN ('ALLOW_SKIP_REVIEWER', 'REQUIRESELFASSESSMENT') and company_id = '#REQUEST.SCookie.COID#'
            </cfquery>
            
            <cfloop query="qCompParam">
                <cfif TRIM(qCompParam.field_code) eq "ALLOW_SKIP_REVIEWER" AND TRIM(qCompParam.field_value) NEQ ''>
                	<cfset allowskipCompParam = TRIM(qCompParam.field_value)>
                <cfelseif TRIM(qCompParam.field_code) eq "REQUIRESELFASSESSMENT" AND TRIM(qCompParam.field_value) NEQ '' >
                	<cfset requireselfassessment = TRIM(qCompParam.field_value)> <!---Bypass self assesment--->
                </cfif>
            </cfloop>
		    <!---Get alloskip param--->
            
		    <!---Get status Request--->
			<cfquery name="local.qCekPMReqCurrentStatus" datasource="#request.sdsn#">
				SELECT status FROM TCLTREQUEST
				WHERE req_type = 'PERFORMANCE.EVALUATION'
					AND req_no = <cfqueryparam value="#FORM.REQUEST_NO#" cfsqltype="cf_sql_varchar">
					AND company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_integer"> 
					AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar"> 
			</cfquery>
		    <!---Get status Request--->
            
		    <!---Email notif--->
            <cfif qCekPMReqCurrentStatus.status EQ 3 > <!---Validasi Jika fully approved--->
                <cfset LOCAL.additionalData = StructNew() >
                <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                
                <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                    template_code = 'PerformanceEvalNotifFullyApproved', 
                    lstsendTo_empid = reviewee_empid , 
                    reviewee_empid = reviewee_empid ,
                    strckData = additionalData
                )>
                
                
            <cfelseif val(FORM.UserInReviewStep)+1 LTE Listlen(FORM.FullListAppr) AND (val(qCekPMReqCurrentStatus.status) neq 0 AND val(qCekPMReqCurrentStatus.status) neq 3) > <!---Validasi ada next approver--->
                <cfif allowskipCompParam EQ 'N' > <!---Tidak bisa skip harus berurutan--->
    		        <cfset LOCAL.lstNextApprover = ListGetAt( FORM.FullListAppr , val(FORM.UserInReviewStep)+1 )><!---hanya get list next approver--->
                <cfelse>
    		        <cfset LOCAL.lstNextApprover = ''><!---all approver dikirim--->
                    <cfloop index="LOCAL.idx" from="#val(FORM.UserInReviewStep)+1#" to="#Listlen(FORM.FullListAppr)#" >
    		            <cfset tempList = ListGetAt( FORM.FullListAppr , idx )><!---get list next approver--->
		                <cfset lstNextApprover = ListAppend(lstNextApprover,tempList) ><!---all approver dikirim--->
                    </cfloop>
                </cfif>
                
                <cfset LOCAL.additionalData = StructNew() >
                <cfset additionalData['REQUEST_NO'] = FORM.REQUEST_NO ><!---Additional Param Untuk template--->
                
                <cfif lstNextApprover NEQ ''>
                    <cfset lstSendEmail = replace(lstNextApprover,"|",",","all")>
                    <cfif reviewee_empid EQ request.scookie.user.empid> <!--- Send by reviewee status not requested --->
                        <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                            template_code = 'PerformanceEvalSubmitByReviewee', 
                            lstsendTo_empid = lstSendEmail , 
                            reviewee_empid = reviewee_empid ,
                            strckData = additionalData
                        )>
                    <cfelse><!--- Send by approver status not requested --->
                        <cfif ListLast(FORM.FullListAppr) EQ lstNextApprover>
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalSubmitToLastApprover', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        <cfelse>
                            <cfset LOCAL.sendEmail = SendNotifEmailEvaluation( 
                                template_code = 'PerformanceEvalSubmitByApprover', 
                                lstsendTo_empid = lstSendEmail , 
                                reviewee_empid = reviewee_empid ,
                                strckData = additionalData
                            )>
                        </cfif>
                    
                    </cfif>
                </cfif>
            </cfif>
            
		</cffunction>
		
		<cffunction name="SendNotifEmailEvaluation">
            <cfparam name="template_code" default=''/>
            <cfparam name="lstsendTo_empid" default=''/>
            <cfparam name="reviewee_empid" default=''/>
            <cfparam name="strckData" default="#StructNew()#" />

            <cfquery name="local.qEmailTemplate" datasource="#REQUEST.SDSN#">
                SELECT subject_#request.scookie.lang# subject,body_#request.scookie.lang# body
                FROM TSFMMAILTemplate
                WHERE template_code = <cfqueryparam value="#template_code#" cfsqltype="cf_sql_varchar">
                    AND status = 1
            </cfquery>
	        
	        <!---replace single bracket to double bracket--->
            <cfset LOCAL.eSubject = qEmailTemplate.subject>
    		<cfset LOCAL.eContent = qEmailTemplate.body>
    
            <cfset LOCAL.foundSingleBracket = false>
    		<cfset LOCAL.ListParamRep = "REQUEST_NO,REVIEWEE_NAME,SYS_NAME,NICKNAME,EMP_NO,REVIEWEE_EMPNO">
    		
    		<cfloop list="#ListParamRep#" index="LOCAL.idxPar">
    		    <cfif FindNoCase("{{#idxPar#}}",eSubject,1) EQ 0 AND FindNoCase("{#idxPar#}",eSubject,1) NEQ 0 >
    			    <cfset eSubject = ReplaceNoCase(eSubject,"{#idxPar#}","{{#idxPar#}}","ALL")>
    		        <cfset LOCAL.foundSingleBracket = true>
    		    </cfif>
    		    <cfif FindNoCase("{{#idxPar#}}",eContent,1) EQ 0 AND FindNoCase("{#idxPar#}",eContent,1) NEQ 0 >
    			    <cfset eContent = ReplaceNoCase(eContent,"{#idxPar#}","{{#idxPar#}}","ALL")>
    		        <cfset LOCAL.foundSingleBracket = true>
    		    </cfif>
    		</cfloop>
    		
    		<cfif foundSingleBracket EQ true> <!---Jika ada single bracket maka update template--->
        	  	<cfquery name="LOCAL.qUpdateTemplate" datasource="#request.sdsn#">
        	        UPDATE TSFMMAILTemplate
        	        SET subject_#request.scookie.lang# =  <cfqueryparam value= "#eSubject#" cfsqltype="cf_sql_varchar">,
        	            body_#request.scookie.lang# =  <cfqueryparam value= "#eContent#" cfsqltype="cf_sql_varchar">
        	        WHERE template_code = <cfqueryparam value= "#template_code#" cfsqltype="cf_sql_varchar">
        	            AND status = 1
                </cfquery>
    		</cfif>
    	    <!---replace single bracket to double bracket--->
        
            <cfquery name="LOCAL.qGetDetailReviewee" datasource="#request.sdsn#">
                SELECT teomemppersonal.email, teomemppersonal.full_name, TEODEMPCOMPANY.emp_no FROM teomemppersonal
                LEFT JOIN TEODEMPCOMPANY 
                    ON TEODEMPCOMPANY.emp_id = teomemppersonal.emp_id
                    AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
                where teomemppersonal.emp_id = <cfqueryparam value="#reviewee_empid#" cfsqltype="cf_sql_varchar">
            </cfquery>

            <cfif qEmailTemplate.recordcount eq 0>
                <cfreturn true>
            </cfif>
            <cfloop list="#lstsendTo_empid#" index="idxapprover">
                <cfquery name="LOCAL.qGetDetailNextApprover" datasource="#request.sdsn#">
                    SELECT teomemppersonal.email, teomemppersonal.full_name, TEODEMPCOMPANY.emp_no FROM teomemppersonal
                    LEFT JOIN TEODEMPCOMPANY 
                        ON TEODEMPCOMPANY.emp_id = teomemppersonal.emp_id
                        AND TEODEMPCOMPANY.company_id = <cfqueryparam value="#REQUEST.SCOOKIE.COID#" cfsqltype="cf_sql_varchar">
                    where teomemppersonal.emp_id = <cfqueryparam value="#idxapprover#" cfsqltype="cf_sql_varchar">
                </cfquery>

                <!--- <cfset LOCAL.eSubject = qEmailTemplate.subject>
                <cfset LOCAL.eContent = qEmailTemplate.body> --->

                <!--- Subject 
                <cfif FindNoCase("{SYS_NAME}",eSubject,1)> 
                    <cfset eSubject = ReplaceNoCase(eSubject,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
                </cfif>

                <cfif FindNoCase("{REQUEST_NO}",eSubject,1) AND StructKeyExists(strckData,'REQUEST_NO' )>
                    <cfset eSubject = ReplaceNoCase(eSubject,"{REQUEST_NO}",#strckData.REQUEST_NO#,"ALL")>
                </cfif>
                
                <cfif FindNoCase("{REVIEWEE_NAME}",eSubject,1) >
                    <cfset eSubject = ReplaceNoCase(eSubject,"{REVIEWEE_NAME}",#HTMLEDITFORMAT(qGetDetailReviewee.full_name)#,"ALL")>
                </cfif>
                Subject --->

                <!--- Content
                <cfif FindNoCase("{NICKNAME}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{NICKNAME}",#HTMLEDITFORMAT(qGetDetailNextApprover.full_name)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{EMP_NO}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{EMP_NO}",#HTMLEDITFORMAT(qGetDetailNextApprover.emp_no)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{REVIEWEE_NAME}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_NAME}",#HTMLEDITFORMAT(qGetDetailReviewee.full_name)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{REVIEWEE_EMPNO}",eContent,1)>
                    <cfset eContent = ReplaceNoCase(eContent,"{REVIEWEE_EMPNO}",#HTMLEDITFORMAT(qGetDetailReviewee.emp_no)#,"ALL")>
                </cfif>
                <cfif FindNoCase("{SYS_NAME}",eContent,1)> >
                    <cfset eContent = ReplaceNoCase(eContent,"{SYS_NAME}",#REQUEST.CONFIG.APP_NAME#,"ALL")>
                </cfif>
                Content --->
                
    			<cfset LOCAL.strckDataParamEmail = {
    				'REVIEWEE_NAME' : HTMLEDITFORMAT(qGetDetailReviewee.full_name),
    				'SYS_NAME' : REQUEST.CONFIG.APP_NAME,
    				'NICKNAME' : HTMLEDITFORMAT(qGetDetailNextApprover.full_name),
    				'EMP_NO' : HTMLEDITFORMAT(qGetDetailNextApprover.emp_no),
    				'REVIEWEE_EMPNO' : HTMLEDITFORMAT(qGetDetailReviewee.emp_no)
    			}>
    			<cfif StructKeyExists(strckData,'REQUEST_NO' )>
    			    <cfset strckDataParamEmail['REQUEST_NO'] = strckData.REQUEST_NO >
    			</cfif>
            			
                <!---
                <cfdump var="eSubject--#eSubject#---eSubject">
                <cfdump var="eContent--#eContent#---eContent">
                to="#qGetDetailNextApprover.email#" 
                --->
                <cfif qGetDetailNextApprover.email neq "">
    				<cf_sfsendmail 
    					template_code="#template_code#" 
    					theform="#LOCAL.strckDataParamEmail#" 
    					to="#qGetDetailNextApprover.email#" 
    					from="#REQUEST.CONFIG.ADMIN_EMAIL#" 
    					lang="#REQUEST.SCOOKIE.LANG#"
    				>
    				<!---
    					StartSymbol="{"
    					EndSymbol="}"
    				--->
                    <!---
                    <cfmail from="#REQUEST.CONFIG.ADMIN_EMAIL#" to="#qGetDetailNextApprover.email#" subject="#eSubject#" type="HTML" failto="#REQUEST.CONFIG.ADMIN_EMAIL#">
                        #eContent#
                    </cfmail>
                    --->
                </cfif>
                
            </cfloop>

            <cfreturn true>
		</cffunction>
		
		
		<cffunction name="CalculateAddDeductPoint">
		    <cfparam name="performance_period" default="">
		    <cfparam name="formno" default="">
		    <cfparam name="reviewee_empid" default="">
		    <cfparam name="empid" default="">
		    
		    <cfparam name="startdate" default="">
		    <cfparam name="enddate" default="">
		    
        	<cfset LOCAL.deductFormula = ''>
        	<cfset LOCAL.deductPoint = ''>
        	<cfset LOCAL.additionalFormula = ''>
        	<cfset LOCAL.additionalPoint = ''>
        	<cfset deductJson = structNew()>
        	<cfset additionalJson = structNew()>
		    
		    <cfquery name="LOCAL.qGetDataPerfPeriod" datasource="#request.sdsn#">
		        SELECT period_code, period_name_#request.scookie.lang# period_name, period_startdate, period_enddate 
		        FROM TPMMPERIOD 
		        WHERE period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
		            AND company_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#request.scookie.cocode#">
		    </cfquery>
		    
		    <cfquery name="LOCAL.qGetDataCompPoint" datasource="#request.sdsn#">
		        SELECT comppoint_code, comp_type, period_code, lst_code, comp_formula, show_history, calc_method 
		        FROM TPMDCOMPPOINT 
		        WHERE period_code = <cfqueryparam value="#performance_period#" cfsqltype="cf_sql_varchar">
		    </cfquery>
		    
		    <!---get and looping deduction component point--->
            <!---Additional and deduction--->
            <cfquery name="qGetAttCodeList" datasource="#request.sdsn#">
                SELECT CPPNT.lst_code, CPPNT.comp_type, CPPNT.comp_formula FROM TPMDCOMPPOINT CPPNT
                INNER JOIN TPMDPERIODCOMPONENT
                    ON TPMDPERIODCOMPONENT.period_code = CPPNT.period_code
                    AND TPMDPERIODCOMPONENT.component_code = 'additionaldeductComp'
                WHERE CPPNT.period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
                <!---AND CPPNT.show_history = 'Y'--->
            </cfquery>
            
            <!---Centang additional and deduction--->
            <cfif qGetAttCodeList.recordcount neq 0>
                <cfset lstAttCode = ''>
                <cfloop query="qGetAttCodeList">
                    <cfset lstAttCode = ListAppend(lstAttCode,qGetAttCodeList.lst_code)>
                </cfloop>
                <cfset lstAttCode = lstAttCode EQ '' ? '-' : lstAttCode >
                <cfquery name="qGetReserveWord" datasource="#request.sdsn#">
                    SELECT word attend_code,description attend_name
                    FROM TSFMRESERVEWORD 
                    WHERE 
                        1 = 1
                        <!--- company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="CF_SQL_VARCHAR"> --->
                        AND word IN (<cfqueryparam value="#lstAttCode#" cfsqltype="cf_sql_varchar" list="yes">)
                </cfquery>
				
                <cfquery name="LOCAL.qGetReserveWord2" datasource="#request.sdsn#">
                    SELECT word attend_code,description attend_name
                    FROM TSFMRESERVEWORD where category IN ('EMPPERSONALFAMILY','ATTINTFDATA','EMPDATA','CUSTOMFIELD','PAYFIELD') 
                </cfquery>
                <cfset lstAttCode = ValueList(qGetReserveWord2.attend_code)>

                <!---<cfset tempsalcalc = ValueFormula(ListChangeDelims(lstAttCode,"|"),reviewee_empid,REQUEST.SCOOKIE.COID,NOW(),"","","N","","","","","N",NOW(),NOW() )>
        	    <cfdump var="#tempsalcalc#">
                --->
                <cfif qGetDataCompPoint.calc_method EQ 'E'> <!---Based on employment date--->
                    <!---Get Career History From Range Date--->
                    <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qGetDateEmpHist" maxrows="1">
                        SELECT 
                            emp_no as EMPNO_HIST,
                            position_code as POSITION_HIST,
                            employmentstatus_code as EMPLOYMENTSTATUS_HIST,
                            grade_code as GRADE_HIST,
                            costcenter_code as COSTCENTER_HIST,
                            worklocation_code as WORKLOCATION_HIST,
                            jobstatus_code as JOBSTATUS_HIST,
                            effectivedt,
                            enddt
                        from TEODEMPLOYMENTHISTORY
                        WHERE company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#REQUEST.SCOOKIE.COID#">
                        AND emp_id = <cfqueryparam VALUE="#reviewee_empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                        
                        AND (
                            (effectivedt >= <cfqueryparam value="#startdate#" cfsqltype="CF_SQL_TIMESTAMP"> AND effectivedt <= <cfqueryparam value="#enddate#" cfsqltype="CF_SQL_TIMESTAMP">)
                            OR 
                            (effectivedt >= <cfqueryparam value="#startdate#" cfsqltype="CF_SQL_TIMESTAMP"> AND enddt <= <cfqueryparam value="#enddate#" cfsqltype="CF_SQL_TIMESTAMP">)
                            <cfif DateCompare( enddate, DateFormat(now()) ) GTE 0 > <!--- Jika param enddate lebih besar dari tannggal hari ini --->
                                OR (effectivedt >= <cfqueryparam value="#startdate#" cfsqltype="CF_SQL_TIMESTAMP"> AND effectivedt <= <cfqueryparam value="#enddate#" cfsqltype="CF_SQL_TIMESTAMP"> AND enddt  IS NULL )
                            </cfif>
                        )
                        <!--- AND effectivedt >= <cfqueryparam value="#startdate#" cfsqltype="CF_SQL_TIMESTAMP">
                        AND effectivedt <= <cfqueryparam value="#enddate#" cfsqltype="CF_SQL_TIMESTAMP"> --->
                        ORDER BY effectivedt DESC
                    </cfquery>
                    <cfif qGetDateEmpHist.recordcount eq 0 OR qGetDateEmpHist.effectivedt EQ ''>
						<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed to calculate, empty employment history data",true)>
						<cfoutput>
							<script>
								alert("#SFLANG#");
							</script>
						</cfoutput>
						<cf_sfabort>
                    </cfif>
                    
                    <cfset LOCAL.tempEnddateParam = qGetDateEmpHist.enddt NEQ '' ? qGetDateEmpHist.enddt : NOW() >
                    <cfset StrctValReserveWord = getValue(lstAttCode,reviewee_empid,REQUEST.SCOOKIE.COID,NOW(),"","","N","","","","",1,qGetDateEmpHist.effectivedt,tempEnddateParam )>
        	    <cfelse>
                    <cfset StrctValReserveWord = getValue(lstAttCode,reviewee_empid,REQUEST.SCOOKIE.COID,NOW(),"","","N","","","","",1,qGetDataPerfPeriod.period_startdate,qGetDataPerfPeriod.period_enddate )>
        	    </cfif>
        	
            	<cfset deductFormula = ''>
            	<cfset deductPoint = ''>
            	<cfset deductJson = structNew()>
            	
            	<cfset additionalFormula = ''>
            	<cfset additionalPoint = ''>
            	<cfset additionalJson = structNew()>
            	
            	<cfset lstValCompCodeAdditional = ''>
            	<cfset lstValCompCodeDeduction = ''>
				
                <cfloop query="qGetAttCodeList">
                    <cfif qGetAttCodeList.comp_type EQ 'D'>
                        <cfset deductFormula = qGetAttCodeList.comp_formula>
						<cfif qGetAttCodeList.lst_code neq "">
							<cfloop list="#qGetAttCodeList.lst_code#" index="attcode">
								<cfset tempValDeduct = 0>
								<cfif attcode EQ 'DISCIPLINE'>
									<cfset qDisciplines = DiscHistListing(asigneeId=reviewee_empid,periodcode=periodcode)>
									<cfset tempValDeduct = val(qDisciplines.recordcount) >
								<cfelseif ListFindNoCase(ValueList(qGetReserveWord.attend_code),attcode) AND StructKeyExists(StrctValReserveWord, attcode) > <!---Reserveword--->
									<cfset tempValDeduct = StrctValReserveWord['#attcode#']>
								<cfelseif LEFT(attcode,1) EQ "'" AND right(attcode,1) EQ "'" AND NOT StructKeyExists(StrctValReserveWord, attcode) > <!---Reserveword--->
									<cfset tempValDeduct = attcode>
								<cfelse>
									<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed to calculate, this Component code or reserve word is invalid:",true)>
									<cfoutput>
										<script>
											alert("#SFLANG# #attcode#");
										</script>
									</cfoutput>
									<cf_sfabort>
									<!---Save lst comcode--->
								</cfif>
								<cfif REFind("[A-Za-z]+", tempValDeduct) >
									<cfset tempValDeduct = LEFT(tempValDeduct,1) EQ "'" AND RIGHT(tempValDeduct,1) EQ "'" ? tempValDeduct : "'#tempValDeduct#'" >
									<cfset deductFormula = replace(deductFormula,attcode,tempValDeduct,"all")>
								<cfelse>
									<cfset deductFormula = replace(deductFormula,attcode,val(tempValDeduct),"all")>
								</cfif>
								<cfset lstValCompCodeDeduction = ListAppend(lstValCompCodeDeduction,attcode)><!---Save lst comcode--->
								<cfset deductJson[attcode] = tempValDeduct >
								
							</cfloop>
							<cftry>
								<cfset deductPoint = evaluate(deductFormula)>
								<cfcatch>
									<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed to calculate, Invalid Deduction Formula",true)>
									<cfoutput>
										<script>
											// alert("#SFLANG# : #cfcatch.message#");
											alert("#SFLANG#");
										</script>
									</cfoutput>
									<cf_sfabort>
								</cfcatch>
							</cftry>
						<cfelse>
							<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed to calculate, there is no selected component in deduction point setting",true)>
							<cfoutput>
								<script>
									alert("#SFLANG#");
								</script>
							</cfoutput>
							<cf_sfabort>
						</cfif>
                        
                        
                    <cfelseif qGetAttCodeList.comp_type EQ 'A'>
                        <cfset additionalFormula = qGetAttCodeList.comp_formula>
						<cfif qGetAttCodeList.lst_code neq "">
						
							<cfloop list="#qGetAttCodeList.lst_code#" index="attcode">
								<cfset tempValAdd = 0>
								<cfif attcode EQ 'AWARD'>
									<cfset qAward = AwardsHistListing(asigneeId=reviewee_empid,periodcode=periodcode)>
									<cfset tempValAdd = val(qAward.recordcount)>
								<cfelseif ListFindNoCase(ValueList(qGetReserveWord.attend_code),attcode) AND StructKeyExists(StrctValReserveWord, attcode) > <!---Reserveword--->
									<cfset tempValAdd = StrctValReserveWord['#attcode#'] >
								<cfelseif LEFT(attcode,1) EQ "'" AND right(attcode,1) EQ "'" AND NOT StructKeyExists(StrctValReserveWord, attcode) > <!---Reserveword--->
									<cfset tempValAdd = attcode>
								<cfelse>
									<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed to calculate, this Component code or reserve word is invalid:",true)>
									<cfoutput>
										<script>
											alert("#SFLANG# #attcode#");
										</script>
									</cfoutput>
									<cf_sfabort>
									<!---Save lst comcode--->
								</cfif>
								
								<cfif REFind("[A-Za-z]+", tempValAdd) >
									<cfset tempValAdd = LEFT(tempValAdd,1) EQ "'" AND RIGHT(tempValAdd,1) EQ "'" ? tempValAdd : "'#tempValAdd#'" >
									<cfset additionalFormula = replace(additionalFormula,attcode,tempValAdd,"all")>
								<cfelse>
									<cfset additionalFormula = replace(additionalFormula,attcode,val(tempValAdd),"all")>
								</cfif>
								<cfset lstValCompCodeAdditional = ListAppend(lstValCompCodeAdditional,attcode)><!---Save lst comcode--->
								<cfset additionalJson[attcode] = tempValAdd >
								
							</cfloop>
							<cftry>
								<cfset additionalPoint = evaluate(additionalFormula)>
								<cfcatch>
									<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed to calculate, Invalid Additional Formula",true)>
									<cfoutput>
										<script>
											// alert("#SFLANG# : #cfcatch.message#");
											alert("#SFLANG#");
										</script>
									</cfoutput>
									<cf_sfabort>
								</cfcatch>
							</cftry>
						
						
						<cfelse>
							<cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSFailed to calculate, there is no selected component in addition point setting",true)>
							<cfoutput>
								<script>
									alert("#SFLANG#");
								</script>
							</cfoutput>
							<cf_sfabort>
						</cfif>
						
                    </cfif>
                </cfloop>
                
                
            </cfif>
            <!---Additional and deduction--->
		    <!---get and looping deduction component point--->
		    <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSCalculation has been completed",true)>
		    <cfoutput>
		        <script>
    		        alert('#SFLANG#');
    		        top.$('[name=deductpoint]').val('#deductPoint#');   
    		        top.$('[class=deductPoint]').html('#deductPoint#');   
    		            $('[class=deductPoint]').html('#deductPoint#');   
    		        top.$('[name=jsonDetailDeductionValue]').val(`#SerializeJSON(deductJson)#`);
    		        top.$('[name=additionalpoint]').val('#additionalPoint#');
    		        top.$('[class=additionalPoint]').html('#additionalPoint#');
    		            $('[class=additionalPoint]').html('#additionalPoint#');
    		        top.$('[name=jsonDetailAdditionalValue]').val(`#SerializeJSON(additionalJson)#`);
    		        top.$('[id=notifneedprocessadditionaldeduct]').hide();
    		        
    		        top.$('[name=startDateCalcMethod]').val('#startdate#'); 
    		        top.$('[name=endDateCalcMethod]').val('#enddate#'); 
    		        
    		        top.calcOverallScore();
		        </script>
		    </cfoutput>
		    
		    
		</cffunction>
        
        <!---Start Custom get Value Formula TCK2102-0626536 alv ------------------------------------------------------------------------------------------------------------- --->
        <cfset _op = '/*+-() !,' & chr(13) & chr(10)>
        <cfset _resWord = 'ROUND,INT,AND,OR,DE,IIF,EQ,GTE,LTE,DATEDIFF,NOW,LEFT,MIN,MAX,GT, ,LT,CONTAINS,MOD,NEQ,YEAR,MONTH,DAY,FINDNOCASE,ISDATE,DAYSINMONTH,CREATEDATE,LISTFINDNOCASE,VAL,FIX,DATEADD,CEILING,IN,CREATEDATETIME,DAYOFWEEK,LEN'> <!--- TCK2006-0574626 --->
        <cfset _strckpayvar = {}>
    
        <cffunction name="ValueFormula"> <!---Salary?--->
            <cfargument name="Formula" default="" required="Yes"><!--- utk list formula delimiternya '|' ya --->
            <cfargument name="empid" default="" required="Yes">
            <cfargument name="companyid" default="#request.scookie.coid#" required="Yes">
            <cfargument name="paydate" default="#now()#"> <!--- utk attendance harian, paydate diisi attend date nya --->
            <cfargument name="periodcode" default=""> <!--- utk Leave, periodcode diisi Leave_code nya --->
            <cfargument name="lookupperiod" default="">
            <cfargument name="flagreim" default="N">
            <cfargument name="allowdeduct_code" default="">
            <cfargument name="attendid" default="">
            <cfargument name="empfamily_id" default="">
            <cfargument name="totalcost" default="">
            <cfargument name="flagpayroll" default="N"> <!--- utk define dari payroll process --->
    
            <cfargument name="startdatePeriod" default="">
            <cfargument name="enddatePeriod" default="">
    
    
            <cfset _op = '/*+-() !,' & chr(13) & chr(10)>
            <cfset LOCAL.objFormula = createobject("component","SFFormula")/>
            
            <cfset Local._Formula = arguments.formula>
            <cfif REQUEST.SCOOKIE.MODE eq "mobileapps" or REQUEST.SCOOKIE.MODE eq "SFGO">
                <cfif IsDefined("FORM.Formula") and IsDefined("FORM.empid") and IsDefined("FORM.companyid")>
                    <cfset Local._Formula = FORM['Formula']>
                    <cfset empid = FORM['empid']>
                    <cfset companyid = FORM['companyid']>
                </cfif>
            </cfif>
        
            <!--- Start Add by Andry for Prorate--->
            <cfset Local.listresprorate = "">
            <!--- End Add by Andry for Prorate--->
            
            <!---<cfoutput>masuk ValueFormula</cfoutput>--->
            <cfif not isDefined("Variables.flagpayroll")>
                <cfset Variables.flagpayroll = arguments.flagpayroll>
            </cfif>
        
            <cfset var detail="">  
            <cfset Local.qResWordDB = objFormula.getResWord(companyid=arguments.companyid)>
            <cfset var resWordDB = ValueList(Local.qResWordDB.word)>
            <cfset Local.rewordreferer = "">
            <cfset var flagcomp = 0>
            
            <cfif len(Local._Formula) eq 0>
                <cfset var formulavalue = 0>
            <cfelse>
                <cfset var complist = ''>
                <cfset var formulavalue = ''>
        
                <cfset Local._Formula = replace(Local._Formula,'+',' + ','ALL')>
                <cfset Local._Formula = replace(Local._Formula,'-',' - ','ALL')>
                <cfset Local._Formula = replace(Local._Formula,'*',' * ','ALL')>
                <cfset Local._Formula = replace(Local._Formula,'/',' / ','ALL')>
                <cfset Local._Formula = replace(Local._Formula,')',' ) ','ALL')>
                <cfset Local._Formula = replace(Local._Formula,'(',' ( ','ALL')>
                <cfset Local._Formula = Local._Formula & ' '>
        
                <cfloop From="1" to="#listlen(Local._Formula,'|')#" Index ="Local.IndexFormula">
                    <cfset var SingleFormula = listgetat(Local._Formula,Local.IndexFormula,'|')>
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,'%','','All')>
                    <cfset Local.LoopCounter = 0>
        
                    <cfloop condition="flagcomp eq 0">
                        <cfset Local.LoopCounter++>
        
                        <cfif findnocase("@","#SingleFormula#") or findnocase("$","#SingleFormula#")>
                            <cfloop List="#SingleFormula#" index="Local.idxformula" delimiters="#_op#">
                                <cfif findnocase("@","#Local.idxformula#")>
                                    <cfset var reserveword = replace(#Local.idxformula#,'@','','ALL')>
    
                                    <cfif trim(reserveword) eq  'SALARY'>
                                        <cfoutput>
                                            <cfquery datasource="#REQUEST.DSN.PAYROLL#" name="Local.qGetFormula">
                                                SELECT #objFormula.SFD('TPYDEMPSALARYPARAMTEMP.new_salary','TPYDEMPSALARYPARAMTEMP.EMP_ID')# as formula_result
                                                FROM TPYDEMPSALARYPARAMTEMP
                                                WHERE emp_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.empid#">
                                                AND company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                                                AND period = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.periodcode#">
                                                AND paydate = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#arguments.paydate#">
                                            </cfquery>
                                        </cfoutput>
    
                                        <cfset Local._Formula = rereplace(Local._Formula,"#Local.idxformula#\b","#val(Local.qGetFormula.formula_result)#","ALL")>
                                        <cfset SingleFormula = rereplace(SingleFormula,"#Local.idxformula#\b","#val(Local.qGetFormula.formula_result)#","ALL")>
                                    <cfelseif listFindNoCase(arguments.allowdeduct_code, reserveword) and listFindNoCase(arguments.allowdeduct_code, reserveword) lt Local.IndexFormula>
                                        <cfset SingleFormula = rereplace(SingleFormula,"#idxformula#\b"," VAR_#reserveword# ","ALL")>
                                        <cfset Local.rewordreferer = listAppend(Local.rewordreferer, "VAR_#reserveword#")>
                                    <cfelse>
                                        <cfquery datasource="#REQUEST.DSN.PAYROLL#" name="Local.qGetFormula">
                                            SELECT allowdeduct_formula, formula_status,
                                                case when formula_status = 'Y' then #objFormula.SFD('TPYDEMPALLOWDEDUCT.formula_result','TPYDEMPALLOWDEDUCT.EMP_ID')# 
                                                ELSE '0' END as formula_result
                                            FROM TPYDEMPALLOWDEDUCT
                                            WHERE emp_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.empid#">
                                            AND company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                                            AND allowdeduct_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#reserveword#">
                                            AND period_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.periodcode#">
                                        </cfquery>
        
                                        <cfif qGetFormula.recordcount eq 0 and arguments.lookupperiod neq "" and arguments.lookupperiod neq arguments.periodcode>
                                            <cfquery datasource="#REQUEST.DSN.PAYROLL#" name="Local.qGetFormula">
                                                SELECT  #objFormula.SFD('a.comp_value','b.EMP_ID')# as formula_result
                                                FROM    TPYDPROCMTDH b
                                                INNER JOIN TPYDPROCMTDD a ON a.procmtdh_id = b.procmtdh_id
                                                WHERE   b.company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                                                    AND b.emp_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.empid#">
                                                    AND b.period_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.lookupperiod#">
                                                    AND b.paydate >= <cfqueryparam value="#CreateDate(Year(arguments.paydate),month(arguments.paydate),1)#" cfsqltype="CF_SQL_DATE"/>
                                                    AND b.paydate < <cfqueryparam value="#DateAdd("m",1,CreateDate(Year(arguments.paydate),month(arguments.paydate),1))#" cfsqltype="CF_SQL_DATE"/>                                             
                                                    AND a.allowdeduct_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#reserveword#">                                               
                                            </cfquery>
                                            
                                            <cfset Local.qGetFormula = queryNew("allowdeduct_formula,formula_status,formula_result","varchar,varchar,integer",{"allowdeduct_formula":"","formula_status":"Y","formula_result":val(Local.qGetFormula.formula_result)})>
                                        </cfif>
        
                                        <cfif Local.qGetFormula.formula_status eq 'Y'>
                                            <cfset Local._Formula = rereplace(Local._Formula,"#Local.idxformula#\b","#val(Local.qGetFormula.formula_result)#","ALL")>
                                            <cfset SingleFormula = rereplace(SingleFormula,"#Local.idxformula#\b","#val(Local.qGetFormula.formula_result)#","ALL")>
                                        <cfelse>
                                            <cfif len(trim(Local.qGetFormula.allowdeduct_formula))>
                                                <!--- Start Add by Andry for Prorate--->
                                                <cfif listFindNoCase(arguments.allowdeduct_code, reserveword) and findnocase("&","#Local.qGetFormula.allowdeduct_formula#")>
                                                    <cfset Local.listresprorate = listAppend(Local.listresprorate, "pro_#reserveword#")>
                                                    <cfset Local._Formula = rereplace(Local._Formula,"#Local.idxformula#\b","(pro_#reserveword#) ","ALL")>
                                                    <cfset SingleFormula = rereplace(SingleFormula,"#Local.idxformula#\b","(pro_#reserveword#) ","ALL")>
                                                <cfelse>
                                                    <cfset Local._Formula = rereplace(Local._Formula,"#Local.idxformula#\b","(#Local.qGetFormula.allowdeduct_formula#) ","ALL")>
                                                    <cfset SingleFormula = rereplace(SingleFormula,"#Local.idxformula#\b","(#Local.qGetFormula.allowdeduct_formula#) ","ALL")>
                                                </cfif>
                                                <!--- Start Add by Andry for Prorate--->
                                            <cfelse>
                                                <cfset Local._Formula = rereplace(Local._Formula,"#Local.idxformula#\b","0 ","ALL")>
                                                <cfset SingleFormula = rereplace(SingleFormula,"#Local.idxformula#\b","0 ","ALL")>
                                            </cfif>
                                        </cfif>
                                    </cfif>
                                <cfelseif findnocase("$","#Local.idxformula#")>
                                    <cfset var reserveword = replace(#Local.idxformula#,'$','','ALL')>
    
                                    <cfif not structKeyExists(_strckpayvar, reserveword)>
                                        <cfset _strckpayvar[reserveword] = getPayVar(reserveword)>
                                    </cfif>
    
                                    <cfset reserveword = 'PV_#reserveword#'>
                                    <cfset Local._Formula = rereplace(Local._Formula,"\#Local.idxformula#\b","#reserveword# ","ALL")>
                                    <cfset SingleFormula = rereplace(SingleFormula,"\#Local.idxformula#\b","#reserveword# ","ALL")>
                                <cfelseif not (findnocase("@","#SingleFormula#") or findnocase("$","#SingleFormula#"))>
                                    <cfbreak>
                                </cfif>
                            </cfloop>
                        <cfelse>
                            <cfset flagcomp = 1>
                        </cfif>
                        <cfif Local.LoopCounter gt 1000>
                            <cfset detail = detail & "<LOG>Iteration overflow, please check formula : #SingleFormula#</LOG>"><cfbreak>
                        </cfif>
                    </cfloop>
        
                    <cfset Local._Formula = replace(Local._Formula,'   ',' ','ALL')>
                    <cfset Local._Formula = replace(Local._Formula,'  ',' ','ALL')>
                    <cfset Local._Formula = trim(Local._Formula)>
        
                    <cfset SingleFormula = replace(SingleFormula,'   ',' ','ALL')>
                    <cfset SingleFormula = replace(SingleFormula,'  ',' ','ALL')>
                    <cfset SingleFormula = replace(SingleFormula,'%','','All')>
                    <cfset SingleFormula = trim(SingleFormula)>
        
                    <cfset Local._Formula = Listsetat(Local._Formula,Local.IndexFormula,SingleFormula,"|")>
    
                    <cfloop List="#SingleFormula#" index="Local.comp" delimiters="#_op#">
                        <cfif not (Local.comp contains "'" or Local.comp contains '"' or isnumeric(Local.comp) or listFind(_resWord,ucase(Local.comp)) or (Local.comp eq ""))>
                            <cfset Local.tempcomp = trim(replace(replace(replace(Local.comp,'@','','All'),'%','','All'),'&','','ALL'))>
                            
                            <cfif not listfind(complist,Local.tempcomp)>
                                <cfset complist = listappend(complist,Local.tempcomp)>
                            </cfif>
                        </cfif>
                    </cfloop>
    
                    <cfset flagcomp = 0>
                </cfloop>
                <cfloop list="#StructKeyList(_strckpayvar)#" index="Local.ikey">
                    <cfloop List="#_strckpayvar[Local.ikey]["complist"]#" index="Local.comp">
                        <cfif not (Local.comp contains "'" or Local.comp contains '"' or isnumeric(Local.comp) or listFind(_resWord,ucase(Local.comp)) or (Local.comp eq ""))>
                            <cfset Local.tempcomp = replace(replace(replace(Local.comp,'@','','All'),'%','','All'),'&','','ALL')>
                            
                            <cfif not listfind(complist,Local.tempcomp)>
                                <cfset complist = listappend(complist,Local.tempcomp)>
                            </cfif>
                        </cfif>
                    </cfloop>                
                </cfloop>
    
                <cfset SingleFormula = ReplaceNoCase(SingleFormula,'%','','All')>
                <cfset complist = ReplaceNoCase(complist,'%','','All')>
                <cfset complist = ReplaceNoCase(complist,'&','','All')>
                <cfset LOCAL.compvaluelist = "">
                <cfset LOCAL.scValVar={}>
    
                <cfif listlen(complist)>
                    <!---edited by agung untuk formula dependent filipin--->
            <!---           <cfset compvaluelist = getValue(complist,arguments.empid,arguments.companyid,arguments.paydate,arguments.periodcode,arguments.lookupperiod,arguments.flagreim,arguments.allowdeduct_code)>--->
                       <!--- <cfset compvaluelist = getValue(complist,arguments.empid,arguments.companyid,arguments.paydate,arguments.periodcode,arguments.lookupperiod,arguments.flagreim,arguments.allowdeduct_code,'',arguments.empfamily_id,arguments.totalcost)>
        
                     --->
                    <cfset scValVar= getValue(complist,arguments.empid,arguments.companyid,arguments.paydate,arguments.periodcode,arguments.lookupperiod,arguments.flagreim,arguments.allowdeduct_code,arguments.attendid,arguments.empfamily_id,arguments.totalcost,true,arguments.startdatePeriod,arguments.enddatePeriod)>
                    <!--- <cfset compvaluelist = scValVar.lstresult> --->
                    <!--- TW, 2015-03-03: assign evaluation results into Variable scope variables instead of replacing them in formula syntax --->
                    <cfset Variables._scValVar= scValVar>
                    
                    <cfloop index="LOCAL.ikey" list="#StructKeyList(scValVar)#">
                        <cfset Variables[ikey]=scValVar[iKey]>
                        <cfset Local[ikey]=scValVar[iKey]>
                    </cfloop>
                    <!---end edit--->
                </cfif>
        
                <cfloop list="#StructKeyList(_strckpayvar)#" index="Local.ikey"> 
                    <cftry>
                        <cfset Local["PV_"&Local.ikey] = val(evaluate("#_strckpayvar[Local.ikey]["formula"]#"))>
                    
                        <cfcatch>
                            <cfset Local["PV_"&Local.ikey] = 0>
        
                            <cfif not StructKeyExists(Local,"qEmpAlert")>
                                <cfquery datasource="#REQUEST.SDSN#" name="Local.qEmpAlert">
                                    SELECT full_name, emp_no,d.emp_id
                                    FROM TEOMEMPPERSONAL m, TEODEMPCOMPANY d
                                    WHERE m.emp_id = d.emp_id
                                    AND m.emp_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.empid#">
                                    AND company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                                </cfquery>
                            </cfif>
        
                            <cfif isdefined("flagpayroll") and flagpayroll neq 'N'>
                                <cfset detail = detail & "<DATA><PROCESS_DETAIL><DATA><STATUS>0</STATUS><EMP_NO>#Local.qEmpAlert.emp_no#</EMP_NO><EMP_NAME>#Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#]</EMP_NAME><EMP_ID>#Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#] : #Local.qEmpAlert.emp_id#</EMP_ID><ERROR>Invalid Payroll Variable Formula (#Local.ikey#) #Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#]</ERROR></DATA></PROCESS_DETAIL></DATA>">
    
                                <cfoutput>
                                    #detail#
                                </cfoutput>
                            </cfif>
                        </cfcatch>
                    </cftry>
                    <!---<cfoutput>Hasil payvar #Local.ikey# = </cfoutput>--->
                </cfloop>
        
                <cftry>
                    <cfset Local.countlistformula = listlen(Local._Formula,'|')>
    
                    <cfloop From="1" to="#Local.countlistformula#" Index ="Local.IdxFormula">
                        <cfset SingleFormula = listgetat(Local._Formula,Local.IdxFormula,'|')>
                        <!--- ENC50115-05916 prorate --->
                        <cfif isArray(arguments.allowdeduct_code)>
                            <cfset local.allowdeduct_code_prorate = arguments.allowdeduct_code> 
                            <cfset local.allowdeduct_code_prorate = listgetat(local.allowdeduct_code_prorate,Local.IdxFormula,',')>
                        <cfelseif not isArray(arguments.allowdeduct_code) and len(arguments.allowdeduct_code) neq 0 >
                            <cfset local.allowdeduct_code_prorate = arguments.allowdeduct_code>
                            <cfset local.allowdeduct_code_prorate = listgetat(local.allowdeduct_code_prorate,Local.IdxFormula,',')>
                        <cfelse>
                            <cfset local.allowdeduct_code_prorate = 'SALARY' >
                        </cfif>
                        
                        <cfif findnocase("&","#SingleFormula#") or findnocase("&","#SingleFormula#")>
                            <cfset var tempformula = SingleFormula>
                            <cfset var SingleFormula = ValueProrate(arguments.periodcode,arguments.empid,"#SingleFormula#","#request.scookie.coid#",arguments.paydate,local.allowdeduct_code_prorate)>
    
                            <cfif len(trim(SingleFormula)) eq 0>
                                <cfset SingleFormula = 0>
                            </cfif>
                            
                            <cfset Local._Formula = ListSetAt(Local._Formula,Local.IdxFormula,SingleFormula,'|')>
                            <cfset Local._Formula = rereplace(Local._Formula,"pro_#local.allowdeduct_code_prorate#\b"," (#SingleFormula#) ","ALL")>
                        </cfif>
                        <!---end ENC50115-05916 prorate --->
                    </cfloop>
                    
                    <cfcatch>
                        <cfset var temp=listToArray(Local._Formula,"|")>
                        <cfset var tempcomp=listToArray(arguments.allowdeduct_code,",")>
                        <cf_sfwritelog dump="cfcatch,arguments,tempcomp,temp" prefix="catch_error_prorate_" ext="html" folder="line8904">
                    </cfcatch>
                </cftry>
            
                <cfset LOCAL.arrFormula=[]>
    
                <cfloop From="1" to="#listlen(Local._Formula,'|')#" Index ="IdxFormula">
                    <cfset SingleFormula = listgetat(Local._Formula,IdxFormula,'|')>
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,'%','','All')>
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,'@','','All')>
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,'$','','All')>
                    <!---<cfloop List="#SingleFormula#" index="comp" delimiters="#_op#">
                        <cfif not (comp contains "'" or comp contains '"' or isnumeric(comp) or listFind(_resWord,ucase(comp)) or (comp eq "")) and ListFindNoCase(resWordDB,comp)>
                            <cfif len(compvaluelist)>
                                <!--- TW, 2015-03-03: previous method of replacing formula syntax with evaluation results, better use the new way by using structure --->
                                <cfset idxcomp = ListFindNoCase(complist,comp)>
                                <cfif idxcomp>
                                    <cfset SingleFormula = Replace(SingleFormula,"#comp#","#ListGetAt(compvaluelist,idxcomp,'~')#")>
                                </cfif>
                            </cfif>
                        </cfif>
                    </cfloop>--->
                    
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,' + ','+','All')>
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,' - ','-','All')>
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,' * ','*','All')>
                    <cfset SingleFormula = ReplaceNoCase(SingleFormula,' / ','/','All')>
            <!---       <cfset formula = ucase(formula)> --->
                    <!--- ENC50115-05916 prorate 
                    <cfif isArray(arguments.allowdeduct_code)>
                        <cfset local.allowdeduct_code_prorate = arguments.allowdeduct_code>
                        <cfset local.allowdeduct_code_prorate = listgetat(local.allowdeduct_code_prorate,IdxFormula,',')>
                    <cfelseif not isArray(arguments.allowdeduct_code) and len(arguments.allowdeduct_code) neq 0 >
                        <cfset local.allowdeduct_code_prorate = arguments.allowdeduct_code>
                        <cfset local.allowdeduct_code_prorate = listgetat(local.allowdeduct_code_prorate,IdxFormula,',')>
                    <cfelse>
                        <cfset local.allowdeduct_code_prorate = 'SALARY' >
                    </cfif>
                    <cfif findnocase("&","#SingleFormula#") or findnocase("&","#SingleFormula#")>
                        <cfset SingleFormula = ValueProrate(arguments.periodcode,arguments.empid,"#SingleFormula#","#request.scookie.coid#",arguments.paydate,local.allowdeduct_code_prorate)>
                    </cfif>
                    end ENC50115-05916 prorate --->
                    <cftry>
                        <cfif isdefined("Variables.flagpayroll") and Variables.flagpayroll neq 'N'>
                            <cfset Local.formularesult = val(evaluate("#SingleFormula#"))>
                            <cfset formulavalue = ListAppend(formulavalue,Local.formularesult,"~")>
                        <cfelse>
                            <cfset Local.formularesult = evaluate("#SingleFormula#")>
                            <cfset formulavalue = ListAppend(formulavalue,Local.formularesult,"~")>
                        </cfif>
    
                        <cfcatch>
                            <cfset Local.formularesult = 0>
                            <cfset formulavalue = ListAppend(formulavalue,Local.formularesult,"~")>
                            <cfset LOCAL.SFLANG=Application.SFParser.TransMLang("JSInvalid Formula",true)>
                            <cfset LOCAL.SFLANG2=Application.SFParser.TransMLang("JSFor Employee",true)>
        
                            <cfif not StructKeyExists(Local,"qEmpAlert")>
                                <cfquery datasource="#REQUEST.SDSN#" name="Local.qEmpAlert">
                                    SELECT full_name, emp_no,d.emp_id
                                    FROM TEOMEMPPERSONAL m, TEODEMPCOMPANY d
                                    WHERE m.emp_id = d.emp_id
                                    AND m.emp_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.empid#">
                                    AND company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                                </cfquery>
                            </cfif>
        
                            <cfif isdefined("flagpayroll") and flagpayroll neq 'N'>
                                <cfset var statusprocess = 0>
                                <!---<cfset detail = detail & "<DATA><STATUS>#statusprocess#</STATUS><EMP_NO>#Local.qEmpAlert.emp_no#</EMP_NO><EMP_NAME>#Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#]</EMP_NAME><EMP_ID>#Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#] : #Local.qEmpAlert.emp_id#</EMP_ID><ERROR>#SFLANG# #Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#] : #JSStringFormat(SingleFormula)#</ERROR></DATA>">--->
                                <!--- BUG51016-69352 --->
                                <cfset detail = detail & "<DATA><PROCESS_DETAIL><DATA><STATUS>#statusprocess#</STATUS><EMP_NO>#Local.qEmpAlert.emp_no#</EMP_NO><EMP_NAME>#Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#]</EMP_NAME><EMP_ID>#Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#] : #Local.qEmpAlert.emp_id#</EMP_ID><ERROR>#SFLANG# #Local.qEmpAlert.full_name# [#Local.qEmpAlert.emp_no#] : #JSStringFormat(SingleFormula)#</ERROR></DATA></PROCESS_DETAIL></DATA>">
    
                                <cfoutput>
                                    #detail#
                                </cfoutput>
                            <cfelse>
                                <cfoutput>
                                    <script>
                                        alert("#SFLANG# : #JSStringFormat(Formula)# #SFLANG2# : #Local.qEmpAlert.full_name# (#Local.qEmpAlert.emp_no#)");
                                        parent.maskButton(false);try{maskButton(false)}catch(err){};
                                    </script>
                                <CF_SFABORT>
                                </cfoutput>
                            </cfif>
                            <!---end ENC50215-06051--->
                        </cfcatch>
                    </cftry>
    
                    <cfif listlen(arguments.allowdeduct_code)>
                        <cfset Local["VAR_#listgetat(arguments.allowdeduct_code,IdxFormula)#"] = Local.formularesult>
                    </cfif>
                </cfloop>
        
                <cfif compvaluelist eq "">
                    <cfloop index="LOCAL.ikey" list="#StructKeyList(scValVar)#">
                        <cfset StructDelete(Variables,ikey)>
                    </cfloop>
                </cfif>
    
                <cfset var lstresult = "">
            </cfif>
            <cfif REQUEST.SCOOKIE.MODE eq "mobileapps" or REQUEST.SCOOKIE.MODE eq "SFGO">
                <cfif IsDefined("FORM.Formula") and IsDefined("FORM.empid") and IsDefined("FORM.companyid")>
                    <cfreturn {formulavalue:#formulavalue#}>
                <cfelse>
                    <cfreturn formulavalue>
                </cfif>
            <cfelse>
                <cfreturn formulavalue>
            </cfif>
        </cffunction>
    
    
    
    
        <cffunction name="getValue">
            <cfargument name="lstreserveword" default="">
            <cfargument name="empid" default="">
            <cfargument name="companyid" default="#request.scookie.coid#">
            <cfargument name="paydate" default="#now()#">
            <cfargument name="periodcode" default="">
            <cfargument name="lookupperiod" default="">
            <cfargument name="flagreim" default="N">
            <cfargument name="allowdeduct_code" default="">
            <cfargument name="attendid" default="">
            <cfargument name="empfamily_id" default="">
            <cfargument name="totalcost" default="">
            <cfargument name="isReturnStruct" default="No" type="boolean">
    
            <cfargument name="startdatePeriod" default="" >
            <cfargument name="enddatePeriod" default="">
            
            <cfset LOCAL.objFormula = createobject("component","SFFormula")/>
            
            <cfset LOCAL.lstresult="">
            <cfset LOCAL.scReturn={lstresult=""}>
            <cfset LOCAL.lstUseKey=lstreserveword>
            
            <cfif Arguments.isReturnStruct>
                <cfset LOCAL.valKey="EW_" & empid & "_" & companyid & "_" & dateformat(paydate,"yyyymmdd") & "_" & periodcode & "_" & lookupperiod & "_" & flagreim & "_" & allowdeduct_code & "_" & attendid & "_" & empfamily_id & "_" & val(totalcost)>
                <cfset valKey=ucase(REReplace(valKey,"[^_A-Za-z0-9]","","ALL"))>
                <cfif StructKeyExists(REQUEST,"EVALWORD")>
                    <cfif StructKeyExists(REQUEST.EVALWORD,valKey)>
                        <cfset lstUseKey=listCompare(lstUseKey,REQUEST.EVALWORD[valKey].lstresult)>
                    <cfelse>
                        <cfset REQUEST.EVALWORD[valKey]={lstresult=""}>
                    </cfif>
                <cfelse>
                    <cfset REQUEST.EVALWORD={"#valKey#"={lstresult=""}}>
                </cfif>
            </cfif>
            
            <cfset arguments.paydate = createodbcdate(arguments.paydate)>
            <!--- <cfset LOCAL.scQInit= objFormula.InitValue(lstUseKey,empid,arguments.companyid,paydate,arguments.periodcode,attendid,empfamily_id)> --->
            <cfset LOCAL.scQInit= InitValue(lstUseKey,empid,arguments.companyid,paydate,arguments.periodcode,attendid,empfamily_id,startdatePeriod,enddatePeriod)>
            
            <!---cst--->
            <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qResWord" >
                SELECT ltrim(rtrim(word)) word, category, data_type FROM TSFMRESERVEWORD
                WHERE company_id IN (<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#,1" list="yes">)
                AND word IN (#ListQualify(replace(replace(Arguments.lstreserveword,'@','','All'),'$','','ALL'),"'",",")#)
                ORDER BY category
            </cfquery>
            <!---cst--->
            
            
            <cfloop index="LOCAL.ikey" list="#StructKeyList(scQInit.QUERY)#">
                <cfset LOCAL[ikey]=scQInit.QUERY[ikey]>
            </cfloop>
            
            <cfset LOCAL.complisth = valueList(qResWord.word)>
            <cfset LOCAL.lstreswordcategory = valueList(qResWord.category)>
            
            <cfloop list="#lstUseKey#" index="LOCAL.reserveword">
                <cfset LOCAL.compvalue = "">
                <cfset LOCAL.idxword = ListFindNoCase(complisth,replace(replace(reserveword,'@','','ALL'),'$','','ALL'))>
        
                <cfif idxword gt 0>
                    <cfset LOCAL.reserveword = replace(replace(reserveword,'@','VAR_','All'),'%','','All')>
                    <cfset LOCAL.reswordcategory = qResWord.category[idxword]>
                    <cfset LOCAL.reswordtype = qResWord.data_type[idxword]>
                    
                    <cfif reswordcategory eq "EMPDATA"> <--- mark --->
                        <cfset Local.listResvword = "EFFECTIVEDATE,LENGTHOFSERVICE_YEAR,LENGTHOFSERVICE_MONTH,LENGTHOFSERVICE_DAY,EMPGENDER">
                    
                        <cfif ListFindNoCase(Local.listResvword,reserveword) OR ListFirst(reserveword,"_") eq "LOS">
                            <cfset LOCAL.compvalue = objFormula.getLengthOfService(arguments.empid,reserveword,qempdata.startdate,qempdata.enddate,paydate,qempdata.gender)>
                        </cfif>
                        <cfif (LOCAL.compvalue eq "" OR LOCAL.compvalue eq 0) and isDefined("qEmpData.#reserveword#")>
                            <cfset LOCAL.compvalue = evaluate("qEmpData.#reserveword#")>
                        </cfif>
                    <cfelseif reswordcategory eq "EMPDATAHISTORY">
                        <cfset LOCAL.compvalue = (isDefined("qEmpDataHistoryProrate.#reserveword#") ? evaluate("qEmpDataHistoryProrate.#reserveword#") : 0) />
                    <cfelseif reswordcategory eq "EMPPERSONAL"> <--- mark --->
                        <cfif LOCAL.compvalue eq "" and isDefined("qEmpPersonal.#reserveword#")>
                            <cfset LOCAL.compvalue = evaluate("qEmpPersonal.#reserveword#")>
                        </cfif>
                    <cfelseif reswordcategory eq "CUSTOMFIELD">
                        <cfif LOCAL.compvalue eq "" and isDefined("qEmpCustomField.#reserveword#")>
                            <cfset LOCAL.compvalue = evaluate("qEmpCustomField.#reserveword#")>
                        </cfif>
                    <cfelseif reswordcategory eq "ATTENDREQUEST">
                        <cfif reserveword eq "ISONDUTY">
                            <cfif qOnduty.recordcount>
                                <cfset LOCAL.compvalue = true>
                            <cfelse>
                                <cfset LOCAL.compvalue = false>
                            </cfif>
                        </cfif>
                    <cfelseif reswordcategory eq "EMPPERSONALFAMILY"> <--- mark --->
                        <cfif reserveword eq "AGEofFAM" OR reserveword eq "ALIVE" OR reserveword eq "DISABILITY" OR reserveword eq "LEGITIMATE" OR reserveword eq "RELATIONSHIP" OR reserveword eq "MARRIED" OR reserveword eq "civil_servant" OR reserveword eq "WORKsameCOMPANY">
                            <cfif qFamily.recordcount>
                                <cfif reserveword eq "AGEofFAM">
                                    <cfset LOCAL.compvalue = qFamily.age>
                                <cfelseif reserveword eq "ALIVE">
                                    <cfset LOCAL.compvalue = qFamily.alive_status>
                                <cfelseif reserveword eq "DISABILITY">
                                    <cfset LOCAL.compvalue = qFamily.DISABILITY>
                                <cfelseif reserveword eq "LEGITIMATE">
                                    <cfset LOCAL.compvalue = qFamily.LEGITIMATE>
                                <cfelseif reserveword eq "RELATIONSHIP">
                                    <cfset LOCAL.compvalue = qFamily.RELATIONSHIP>
                                <cfelseif reserveword eq "MARRIED">
                                    <cfset LOCAL.compvalue = qFamily.Marital_status>
                                <cfelseif reserveword eq "GENDERofFAM">
                                    <cfset LOCAL.compvalue = qFamily.Gender>
                                <cfelseif reserveword eq "civil_servant">
                                    <cfset LOCAL.compvalue = qFamily.status_goverment>
                                <cfelseif reserveword eq "WORKsameCOMPANY">
    
                                    <cfquery name="LOCAL.getDataFamSameLoc" dbtype="query">
                                        SELECT * FROM qFamily
                                        where  familyemp_id = 1
                                            <!--- AND company = '#request.scookie.coid#' --->
                                    </cfquery>
    
                                    <cfset LOCAL.compvalue = getDataFamSameLoc.recordcount>
                                </cfif>
                            </cfif>
                        </cfif>
                    <cfelseif reswordcategory eq "EMPHISTORY_DIEPVU">
                        <cfif reserveword eq "EFFDT_CURRPOS" OR reserveword eq "LOS_CURRPOS">
                            <cfif qEmpDiepVu.RecordCount>
                                <cfif reserveword eq "EFFDT_CURRPOS">
                                    <cfset LOCAL.compvalue = qEmpDiepVu.EFFECTIVEDT>
                                <cfelseif reserveword eq "LOS_CURRPOS">
                                    <cfset LOCAL.compvalue = INT(DateDiff("m",qEmpDiepVu.EFFECTIVEDT,arguments.paydate)/12)>
                                </cfif>
                            </cfif>
                        </cfif>
                    <cfelseif reswordcategory eq "ATTENDDATA"> <--- mark --->
                        <cfif reserveword eq "SHIFTCODE" OR reserveword eq "SHIFTGROUP" OR reserveword eq "DAYTYPE" OR reserveword eq "STARTTIME" OR reserveword eq "ENDTIME" OR reserveword eq "SHIFTSTART" OR reserveword eq "SHIFTEND" OR reserveword eq "LSTATTENDSTS">
                            <cfif qAttendData.recordcount>
                                <cfif reserveword eq "SHIFTCODE">
                                    <cfset LOCAL.compvalue = qAttendData.shiftdaily_code>
                                <cfelseif reserveword eq "SHIFTGROUP">
                                    <cfset LOCAL.compvalue = qAttendData.shiftgroupcode>
                                <cfelseif reserveword eq "DAYTYPE">
                                    <cfset LOCAL.compvalue = qAttendData.daytype>
                                <cfelseif reserveword eq "STARTTIME">
                                    <cfset LOCAL.compvalue = qAttendData.starttime>
                                <cfelseif reserveword eq "ENDTIME">
                                    <cfset LOCAL.compvalue = qAttendData.endtime>
                                <cfelseif reserveword eq "SHIFTSTART">
                                    <cfset LOCAL.compvalue = qAttendData.shiftstarttime>
                                <cfelseif reserveword eq "SHIFTEND">
                                    <cfset LOCAL.compvalue = qAttendData.shiftendtime>
                                <cfelseif reserveword eq "LSTATTENDSTS">
                                    <cfset LOCAL.compvalue = qAttendData.lstattendsts>
                                </cfif>
                            <cfelse>
                                <cfset var objSFAttendance = CreateObject("component","SFAttendance")>
                                <cfset var qEmpDefaultShift = objSFAttendance.GetDefaultShift(arguments.empid,arguments.companyid,arguments.paydate,'Y')>
                                
                                <cfif qEmpDefaultShift.recordcount>
                                    <cfif reserveword eq "SHIFTCODE">
                                        <cfset LOCAL.compvalue = qEmpDefaultShift.ShiftDailyCode>
                                    <cfelseif reserveword eq "SHIFTGROUP">
                                        <cfset LOCAL.compvalue = qEmpDefaultShift.shiftgroupcode>
                                    <cfelseif reserveword eq "DAYTYPE">
                                        <cfset LOCAL.compvalue = qEmpDefaultShift.daytype>
                                    <cfelseif reserveword eq "STARTTIME">
                                        <cfset LOCAL.compvalue = ''>
                                    <cfelseif reserveword eq "ENDTIME">
                                        <cfset LOCAL.compvalue = ''>
                                    <cfelseif reserveword eq "SHIFTSTART">
                                        <cfset LOCAL.compvalue = qEmpDefaultShift.shiftstarttime>
                                    <cfelseif reserveword eq "SHIFTEND">
                                        <cfset LOCAL.compvalue = qEmpDefaultShift.shiftendtime>
                                    <cfelseif reserveword eq "LSTATTENDSTS">
                                        <cfset LOCAL.compvalue = ''>
                                    </cfif>
                                </cfif>
                            </cfif>
                        </cfif>
                        <cfif LOCAL.compvalue eq "" and isDefined("qAttendData.#reserveword#")>
                            <cfset LOCAL.compvalue = evaluate("qAttendData.#reserveword#")>
                        </cfif>
                        <!---BP--->
                        <cfif reserveword eq 'LEAVEPAYOUT'>
                            <cfset LOCAL.compvalue = getLeavePayout(arguments.companyid,arguments.periodcode,arguments.empid)>
                        </cfif>
                        <!---End: BP--->
                    <cfelseif reswordcategory eq "BREAKDATA">
                        <cfif reserveword eq "SHIFTBREAKSTART" OR reserveword eq "SHIFTBREAKEND" OR reserveword eq "BREAKSTART" OR reserveword eq "BREAKEND">
                            <cfif qBreakData.recordcount>
                                <cfif reserveword eq "SHIFTBREAKSTART">
                                    <cfset LOCAL.compvalue = qBreakData.shift_breakstart>
                                <cfelseif reserveword eq "SHIFTBREAKEND">
                                    <cfset LOCAL.compvalue = qBreakData.shift_breakend>
                                <cfelseif reserveword eq "BREAKSTART">
                                    <cfset LOCAL.compvalue = qBreakData.break_start>
                                <cfelseif reserveword eq "BREAKEND">
                                    <cfset LOCAL.compvalue = qBreakData.break_end>
                                </cfif>
                            </cfif>
                        </cfif>
                    <cfelseif reswordcategory eq "SYSCALC"> <--- mark --->
                        <cfset LOCAL.compvalue = val(extraleavecalc(arguments.empid,arguments.companyid,reserveword,totalcost,arguments.empfamily_id))>
                    <cfelseif reswordcategory eq "ATTINTFDATA"> <--- mark --->
                        <cfset LOCAL.lstattcomp = valueList(qAttIntfDataSum.attcomponent)>
                        
                        <cfif right(reserveword,6) eq "_DAILY" AND isDefined("qAttIntfDataSum.attcompdaily_value")>
                            <cfset LOCAL.tempresword = LEFT(reserveword,LEN(reserveword)-6)>
                        
                            <cfif ListFindNoCase(lstattcomp,tempresword)>
                                <cfset LOCAL.compvalue = qAttIntfDataSum.attcompdaily_value[ListFindNoCase(lstattcomp,tempresword)]>
                            </cfif>
                        <cfelse>
                            <cfif ListFindNoCase(lstattcomp,reserveword)>
                                <cfset LOCAL.compvalue = qAttIntfDataSum.attcomponent_value[ListFindNoCase(lstattcomp,reserveword)]>
                            </cfif>
                        </cfif>
                    <cfelseif reswordcategory eq "PAYDATA">
                        <cfif left(reserveword,4) eq "VAR_">
                            <cfset LOCAL.tempresword = RIGHT(reserveword,LEN(reserveword)-4)>
                        <cfelse>
                            <cfset LOCAL.tempresword = reserveword>
                        </cfif>
                        
                        <cfset LOCAL.qPeriod = objFormula.getPeriod(periodcode=arguments.periodcode,paydate=arguments.paydate)>
                        
                        <cfif tempresword eq 'PAYDATE'>
                            <cfset LOCAL.compvalue = arguments.paydate>
                        <cfelseif tempresword eq "PREVSAL">
                            <cfoutput>
                                <cfquery datasource="#REQUEST.DSN.PAYROLL#" name="LOCAL.qEmpDataHistoryPREV">
                                    SELECT TPYDEMPSALARYPARAMHISTORY.currency_code,
                                    #objFormula.SFD('TPYDEMPSALARYPARAMHISTORY.salary','TPYDEMPSALARYPARAMHISTORY.emp_id')# as salary
                                    FROM TPYDEMPSALARYPARAMHISTORY
                                    WHERE TPYDEMPSALARYPARAMHISTORY.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" cfsqltype="CF_SQL_VARCHAR">
                                    AND TPYDEMPSALARYPARAMHISTORY.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                                    AND TPYDEMPSALARYPARAMHISTORY.effective_date <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="cf_sql_timestamp"/>
                                    ORDER BY effective_date desc
                                </cfquery>
                            </cfoutput>
                        
                            <cfset LOCAL.compvalue = val(qEmpDataHistoryPREV.salary)>
                        <cfelseif tempresword eq "TOTAL_COST">
                            <cfset LOCAL.compvalue = getTotalCost(
                                                                        empid=arguments.empid
                                                                        ,periodcode=arguments.periodcode
                                                                    )>
                            
                        <cfelseif tempresword eq 'LIMITPROCDATE'>
                            <cfset LOCAL.compvalue = dateformat(qPeriod.limitdate)>
                        <cfelseif tempresword eq 'PAYPERSTARTDATE'>
                            <cfset LOCAL.compvalue = dateformat(qPeriod.salarystartdate)>
                        <cfelseif tempresword eq 'PAYPERENDDATE'>
                            <cfset LOCAL.compvalue = dateformat(qPeriod.salaryenddate)>
                        <cfelseif tempresword eq "SALARY">
                            <cfif arguments.flagreim eq 'Y'> <!--- Untuk reimbursement --->
                                <cfset Local.referencedate = arguments.paydate>
                                
                                <cfif qPeriod.usesalary eq "Y" and isdate(qPeriod.salaryenddate)>
                                    <cfset Local.referencedate = qPeriod.salaryenddate>
                                </cfif>
        
                                <cfif datediff("d",Local.referencedate,qPayData.effective_date) gt 0>
                                    <cfoutput>                              
                                        <cfquery name="LOCAL.qEmpDataHistory" datasource="#request.DSN.PAYROLL#">
                                            SELECT TPYDEMPSALARYPARAMHISTORY.currency_code, #objFormula.SFD('TPYDEMPSALARYPARAMHISTORY.salary','TPYDEMPSALARYPARAMHISTORY.emp_id')# as salary
                                            FROM TPYDEMPSALARYPARAMHISTORY
                                            WHERE TPYDEMPSALARYPARAMHISTORY.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                            AND TPYDEMPSALARYPARAMHISTORY.company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                                            AND TPYDEMPSALARYPARAMHISTORY.effective_date <= <cfqueryparam value="#Local.referencedate#" cfsqltype="cf_sql_date"/>
                                            ORDER BY effective_date desc
                                        </cfquery>
                                    </cfoutput>
    
                                    <cfset LOCAL.compvalue = val(precisionEvaluate(qEmpDataHistory.salary))>
                                <cfelse>
                                    <cfset LOCAL.compvalue = precisionEvaluate(qPayData.salary)>
                                </cfif>
                            <cfelse>
                                <cfif qPeriod.usesalary eq "Y">
                                    <cfif left(reserveword,4) eq "VAR_">
                                        <cfif datediff("d",qPeriod.salarystartdate,qPayData.effective_date) gt 0>
                                            <cfif datediff("d",qPeriod.salaryenddate,qPayData.effective_date) lte 0>
                                                <cfset LOCAL.compvalue = ValueFormula(qPayData.formula,arguments.empid,arguments.companyid,qPayData.effective_date,arguments.periodcode)>
                                            <cfelse>
                                                <cfset LOCAL.compvalue = 0>
                                            </cfif>
        
                                            <cfquery name="LOCAL.qEmpDataHistory" datasource="#request.DSN.PAYROLL#">
                                                SELECT TPYDEMPSALARYPARAMHISTORY.effective_date, TPYDEMPSALARYPARAMHISTORY.formula
                                                FROM TPYDEMPSALARYPARAMHISTORY
                                                WHERE TPYDEMPSALARYPARAMHISTORY.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                                AND TPYDEMPSALARYPARAMHISTORY.company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                                                AND TPYDEMPSALARYPARAMHISTORY.effective_date > <cfqueryparam value="#CreateODBCDate(qPeriod.salarystartdate)#" cfsqltype="cf_sql_timestamp"/>
                                                AND TPYDEMPSALARYPARAMHISTORY.effective_date <= <cfqueryparam value="#CreateODBCDate(qPeriod.salaryenddate)#" cfsqltype="cf_sql_timestamp"/>
                                                ORDER BY effective_date desc
                                            </cfquery>
        
                                            <cfif qEmpDataHistory.recordcount>
                                                <cfset LOCAL.proratesalary = 0>
    
                                                <cfloop query="qEmpDataHistory">
                                                    <cfset proratesalary = proratesalary + ValueFormula(qEmpDataHistory.formula,arguments.empid,arguments.companyid,qEmpDataHistory.effective_date,arguments.periodcode)>
                                                </cfloop>
                                                
                                                <cfset LOCAL.compvalue = LOCAL.compvalue + proratesalary>
                                            <cfelse>
                                                <cfoutput>
                                                    <cfquery name="LOCAL.qEmpDataHistory" datasource="#request.DSN.PAYROLL#">
                                                        SELECT TPYDEMPSALARYPARAMHISTORY.formula
                                                        FROM TPYDEMPSALARYPARAMHISTORY
                                                        WHERE TPYDEMPSALARYPARAMHISTORY.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                                        AND TPYDEMPSALARYPARAMHISTORY.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                                                        AND TPYDEMPSALARYPARAMHISTORY.effective_date <= <cfqueryparam value="#CreateODBCDate(qPeriod.salarystartdate)#" cfsqltype="CF_SQL_TIMESTAMP"/>
                                                        ORDER BY effective_date desc
                                                    </cfquery>
                                                </cfoutput>
    
                                                <cfif qEmpdataHistory.recordcount>
                                                    <cfset LOCAL.compvalue = LOCAL.compvalue + ValueFormula(qEmpDataHistory.formula,arguments.empid,arguments.companyid,qPeriod.salarystartdate,arguments.periodcode)>
                                                </cfif>
                                            </cfif>
                                        <cfelse>
                                            <cfif qPayData.formula eq "SALARY">
                                                <cfset LOCAL.compvalue = precisionEvaluate(qPayData.salary)>
                                            <cfelse>
                                                <cfset LOCAL.compvalue = ValueFormula(qPayData.formula,arguments.empid,arguments.companyid,qPeriod.salarystartdate,arguments.periodcode)>
                                            </cfif>
                                        </cfif>
                                    <cfelse>
                                        <cfif len(trim(qPayData.effective_date)) AND datediff("d",qPeriod.salaryenddate,qPayData.effective_date) gt 0>
                                            <cfoutput>
                                                <cfquery name="LOCAL.qEmpDataHistory" datasource="#request.DSN.PAYROLL#">
                                                    SELECT TPYDEMPSALARYPARAMHISTORY.currency_code, #objFormula.SFD('TPYDEMPSALARYPARAMHISTORY.salary','TPYDEMPSALARYPARAMHISTORY.emp_id')# as salary
                                                    FROM TPYDEMPSALARYPARAMHISTORY
                                                    WHERE TPYDEMPSALARYPARAMHISTORY.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                                    AND TPYDEMPSALARYPARAMHISTORY.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                                                    AND TPYDEMPSALARYPARAMHISTORY.effective_date <= <cfqueryparam value="#arguments.paydate#" cfsqltype="CF_SQL_TIMESTAMP"/>
                                                    ORDER BY effective_date desc
                                                </cfquery>
                                            </cfoutput>
    
                                            <cfif qEmpdataHistory.recordcount>
                                                <cfset LOCAL.compvalue = precisionEvaluate(qEmpDataHistory.salary)>
                                            </cfif>
                                        <cfelse>
                                            <cfset LOCAL.compvalue = precisionEvaluate(qPayData.salary)>
                                        </cfif>
                                    </cfif>
                                <cfelse>
                                    <cfif arguments.lookupperiod neq "" AND arguments.lookupperiod neq arguments.periodcode>
                                        <cfset LOCAL.compvalue = getValue(reserveword,arguments.empid,arguments.companyid,arguments.paydate,arguments.lookupperiod,arguments.lookupperiod,arguments.startdatePeriod,arguments.enddatePeriod)>
                                    <cfelse>
                                        <cfset LOCAL.compvalue = 0>
                                    </cfif>
                                </cfif>
                            </cfif>
                        </cfif>
                        <cfif (LOCAL.compvalue eq "" OR LOCAL.compvalue eq 0) and isDefined("qPayData.#reserveword#")>
                            <cfset LOCAL.compvalue = evaluate("qPayData.#reserveword#")>
                        </cfif>
                    <cfelseif reswordcategory eq "PAYFIELD">
                        <cfset LOCAL.lstpayfieldno = valueList(qPayField.payfield_no)>
    
                        <cfif RIGHT(reserveword,5) eq "_DATE">
                            <cfset LOCAL.tempresword = ReplaceNoCase(reserveword,"_DATE","")>
                            <cfset LOCAL.tempfieldno = ReplaceNoCase(tempresword,"PAYFIELD","")>
                        
                            <cfif ListFindNoCase(lstpayfieldno,tempfieldno)>
                                <cfset LOCAL.compvalue = qPayField.payfield_date[ListFindNoCase(lstpayfieldno,tempfieldno)]>
                            </cfif>
                        <cfelse>
                            <cfset LOCAL.tempfieldno = ReplaceNoCase(reserveword,"PAYFIELD","")>
                            <cfset LOCAL.idxno = ListFindNoCase(lstpayfieldno,tempfieldno)>
                        
                            <cfif idxno neq 0>
                                <cfif isDefined("arguments.paydate") and len(trim(qPayField.payfield_date[idxno])) and len(trim(arguments.paydate)) and datediff("d",arguments.paydate,qPayField.payfield_date[idxno]) gt 0>
                                    <cfquery name="LOCAL.qPayFieldHistory" datasource="#REQUEST.SDSN#">
                                        SELECT value payfeild_value FROM TPYDEMPPAYFIELDHISTORY
                                        WHERE EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                        and company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                                        and effective_date <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP"/>
                                        AND payfield_no = <cfqueryparam value="#LOCAL.tempfieldno#"  cfsqltype="CF_SQL_integer"/>
                                        ORDER BY effective_date desc
                                    </cfquery>
    
                                    <cfset LOCAL.compvalue = val(qPayFieldHistory.payfeild_value[1])>
                                <cfelse>
                                    <cfset LOCAL.compvalue = qPayField.payfield_value[idxno]>
                                </cfif>
                            </cfif>
                        </cfif>
                    <cfelseif reswordcategory eq "PAYCOMP">
                        <cfset LOCAL.lstpaycomp = valueList(qPayComp.allowdeduct_code)>  
                                     
                        <cfif ListFindNoCase(lstpaycomp,reserveword)>                    
                            <cfset LOCAL.compvalue = getcompvalue(arguments.empid,arguments.companyid,arguments.periodcode,paydate,reserveword)> <!--- TCK1909-0521956 --->
                        <cfelseif LEFT(reserveword,4) eq "VAR_">
                            <cfset LOCAL.tempcomp = RIGHT(reserveword,LEN(reserveword)-4)>
                            <cfset LOCAL.idxcomp = ListFindNoCase(lstpaycomp,tempcomp)>
    
                            <cfif idxcomp neq 0>
                                <cfif qPayComp.formula_status[idxcomp] eq "Y">
                                    <cfset LOCAL.compvalue = qPayComp.formula_result[idxcomp]>
                                <cfelse>
                                    <cfset LOCAL.compvalue = ValueFormula(qPayComp.allowdeduct_formula[idxcomp],arguments.empid,arguments.companyid,arguments.paydate,arguments.periodcode)>
                                </cfif>
                            <cfelseif arguments.lookupperiod neq "" AND arguments.lookupperiod neq arguments.periodcode>
                                <cfset LOCAL.compvalue = getValue(reserveword,arguments.empid,arguments.companyid,arguments.paydate,arguments.lookupperiod,arguments.lookupperiod,arguments.startdatePeriod,arguments.enddatePeriod)>
                            </cfif>
                        <cfelseif RIGHT(reserveword,5) eq "_DATE">
                            <cfset LOCAL.tempcomp = LEFT(reserveword,LEN(reserveword)-5)>
                            <cfset LOCAL.idxcomp = ListFindNoCase(lstpaycomp,tempcomp)>
    
                            <cfif idxcomp neq 0>
                                <cfset LOCAL.compvalue = qPayComp.effective_date[idxcomp]>
                            <cfelseif arguments.lookupperiod neq "" AND arguments.lookupperiod neq arguments.periodcode>
                                <cfset LOCAL.compvalue = getValue(reserveword,arguments.empid,arguments.companyid,arguments.paydate,arguments.lookupperiod,arguments.lookupperiod,arguments.startdatePeriod,arguments.enddatePeriod)>
                            </cfif>
                        <!---BP--->
                        <cfelseif RIGHT(reserveword,4) eq "_YTD">
                            <cfset LOCAL.tempcomp = LEFT(reserveword,LEN(reserveword)-4)>
                            <cfset LOCAL.idxcomp = ListFindNoCase(lstpaycomp,tempcomp)>
                            <cfset LOCAL.qYTD = getYTD(LOCAL.tempcomp,arguments.paydate,arguments.empid)>
    
                            <cfif qYTD.recordcount AND qYTD.compvalue neq '' >
                                <cfset LOCAL.compvalue = #qYTD.compvalue#>
                            <cfelse>
                                <cfset LOCAL.compvalue = 0>
                            </cfif>
                        <!---END: BP--->
                        <cfelseif RIGHT(reserveword,5) eq "_PREV">
                        <cfelseif ListFindNoCase("PERFCONCL,PERFSCORE",reserveword)>
                            <cfset LOCAL.compvalue = PerformancePayrollComponent(arguments.empid,reserveword)>
                        <cfelse>
                            <cfif arguments.lookupperiod neq "" AND arguments.lookupperiod neq arguments.periodcode>
                                <cfset LOCAL.compvalue = getValue(reserveword,arguments.empid,arguments.companyid,arguments.paydate,arguments.lookupperiod,arguments.lookupperiod,arguments.startdatePeriod,arguments.enddatePeriod)>
                            </cfif>
                        </cfif>
                        <cfif LOCAL.compvalue eq "" and isDefined("qPayComp.#reserveword#")>
                            <cfset LOCAL.compvalue = evaluate("qPayComp.#reserveword#")>
                        </cfif>
                    <cfelseif reswordcategory eq "LNDATA">
                        <cfset LOCAL.compvalue = 0>
                        
                        <cfif qLoanData.recordcount>
                            <cfset LOCAL.lstLoanCode = valuelist(qLoanData.loan_code)>
                        <cfelse>
                            <cfset LOCAL.lstLoanCode = "">
                        </cfif>
                        <cfif listfindnocase(lstLoanCode,reserveword)>
                            <cfquery name="LOCAL.qLoan" datasource="#REQUEST.SDSN#">
                                SELECT COALESCE(SUM(payment),0) as compvalue
                                FROM TLNDLOANPROCESS
                                WHERE emp_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                                AND pay_period = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND pay_date BETWEEN  <cfqueryparam VALUE="#createdate(year(arguments.paydate),month(arguments.paydate),1)#" CFSQLTYPE="CF_SQL_DATE">
                                AND  <cfqueryparam VALUE="#createdate(year(arguments.paydate),month(arguments.paydate),daysinmonth(arguments.paydate))#" CFSQLTYPE="CF_SQL_DATE">
                                AND loan_code =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#reserveword#">
                                AND direct_payment = 0
                                AND paid = 1
                            </cfquery>
    
                            <cfif qLoan.compvalue neq '' >
                                <cfset LOCAL.compvalue = #qLoan.compvalue#>
                            </cfif>
                        </cfif>
    
                        <cfif RIGHT(reserveword,5) eq "_DISB">
                            <cfset LOCAL.lenCode = LEFT(reserveword,LEN(reserveword)-5)>
                            <cfset LOCAL.newDisburseCode = ListFindNoCase(lstLoanCode,lenCode)>
    
                            <cfquery name="LOCAL.qLoan" datasource="#REQUEST.SDSN#">
                                SELECT COALESCE(sum(TLNDLOANMASTER.loan_amount),0) compvalue
                                FROM TLNDLOANMASTER,TLNRLOANMASTERPERIOD,TPYMPAYPERIOD
                                WHERE TLNDLOANMASTER.emp_id =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                                AND TLNDLOANMASTER.loan_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lenCode#">
                                AND TLNDLOANMASTER.loan_no = TLNRLOANMASTERPERIOD.loan_no
                                AND TLNRLOANMASTERPERIOD.period_code = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND TPYMPAYPERIOD.period_code = TLNRLOANMASTERPERIOD.period_code
                                AND month(TLNDLOANMASTER.disburse_date) =  <cfqueryparam VALUE="#Month(arguments.paydate)#" CFSQLTYPE="CF_SQL_INTEGER">
                                AND year(TLNDLOANMASTER.disburse_date) =  <cfqueryparam VALUE="#YEAR(arguments.paydate)#" CFSQLTYPE="CF_SQL_INTEGER">
                            </cfquery>
    
                            <cfif IsDefined("qLoan.compvalue") AND qLoan.compvalue neq '' >
                                <cfset LOCAL.compvalue = #qLoan.compvalue#>
                            <cfelse>
                                <cfset LOCAL.compvalue = 0>
                            </cfif>
                        </cfif>
        
                        <cfif RIGHT(reserveword,6) eq "_ALLOW">
                            <cfset LOCAL.lenCode = LEFT(reserveword,LEN(reserveword)-6)>
                            <cfset LOCAL.newAllowCode = ListFindNoCase(lstLoanCode,lenCode)>
    
                            <cfquery name="qLoan" datasource="#REQUEST.SDSN#">
                                SELECT  COALESCE(sum(Subsidized_Amount),0)  as compvalue
                                FROM TLNDLOANPROCESS WHERE emp_id =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                                AND pay_period = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND pay_date BETWEEN  <cfqueryparam VALUE="#createdate(year(arguments.paydate),month(arguments.paydate),1)#" CFSQLTYPE="CF_SQL_DATE">
                                AND  <cfqueryparam VALUE="#createdate(year(arguments.paydate),month(arguments.paydate),daysinmonth(arguments.paydate))#" CFSQLTYPE="CF_SQL_DATE">
                                AND loan_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lenCode#">
                                AND direct_payment = 0
                                AND pay_period = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND paid = 1
                            </cfquery>
    
                            <cfif qLoan.compvalue neq '' >
                                <cfset LOCAL.compvalue = #qLoan.compvalue#>
                            </cfif>
                        </cfif>
        
                        <!---16082016 start fix ENC50716-80503--->
                        <cfif RIGHT(reserveword,8) eq "_CAPITAL">
                            <cfset LOCAL.lenCode = LEFT(reserveword,LEN(reserveword)-8)>
                            <cfset LOCAL.newAllowCode = ListFindNoCase(lstLoanCode,lenCode)>
    
                            <cfquery name="qLoan" datasource="#REQUEST.SDSN#">
                                SELECT  COALESCE(sum(principal),0)  as compvalue
                                FROM TLNDLOANPROCESS WHERE emp_id =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                                AND pay_period = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND month(pay_date) = <cfqueryparam VALUE="#Month(arguments.paydate)#" CFSQLTYPE="CF_SQL_INTEGER">
                                AND year(pay_date) = <cfqueryparam VALUE="#year(arguments.paydate)#" CFSQLTYPE="CF_SQL_INTEGER">
                                AND loan_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lenCode#">
                                AND direct_payment = 0
                                AND pay_period = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND paid = 1
                            </cfquery>
    
                            <cfif IsDefined("qLoan.compvalue") AND qLoan.compvalue neq '' >
                                <cfset LOCAL.compvalue = #qLoan.compvalue#>
                            <cfelse>
                                <cfset LOCAL.compvalue = 0>
                            </cfif>
                        </cfif>
                        <cfif RIGHT(reserveword,9) eq "_INTEREST">
                            <cfset LOCAL.lenCode = LEFT(reserveword,LEN(reserveword)-9)>
                            <cfset LOCAL.newAllowCode = ListFindNoCase(lstLoanCode,lenCode)>
    
                            <cfquery name="qLoan" datasource="#REQUEST.SDSN#">
                                SELECT  COALESCE(sum(interestmoney),0)  as compvalue
                                FROM TLNDLOANPROCESS WHERE emp_id =  <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                                AND pay_period = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND month(pay_date) = <cfqueryparam VALUE="#Month(arguments.paydate)#" CFSQLTYPE="CF_SQL_INTEGER">
                                AND year(pay_date) = <cfqueryparam VALUE="#year(arguments.paydate)#" CFSQLTYPE="CF_SQL_INTEGER">
                                AND loan_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lenCode#">
                                AND direct_payment = 0
                                AND pay_period = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND paid = 1
                            </cfquery>
    
                            <cfif IsDefined("qLoan.compvalue") AND qLoan.compvalue neq '' >
                                <cfset LOCAL.compvalue = #qLoan.compvalue#>
                            <cfelse>
                                <cfset LOCAL.compvalue = 0>
                            </cfif>
                        </cfif>
                        <!---16082016 end fix ENC50716-80503--->
                    <cfelseif reswordcategory eq "RMINTFDATA">
                        <cfset LOCAL.lstreim_code = valueList(qReimInterface.reim_code)>
    
                        <cfquery name="LOCAL.qCurrCodeAllDed" datasource="#REQUEST.SDSN#">
                            SELECT currency_code
                                FROM TPYDEMPALLOWDEDUCT
                                WHERE emp_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                                AND allowdeduct_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.allowdeduct_code#">
                                AND company_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.companyid#">
                                AND period_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.periodcode#">
                        </cfquery>
    
                        <cfset LOCAL.compvalue = 0>
                        <cfset LOCAL.no = 1>
    
                        <cfloop list="#lstreim_code#" index="LOCAL.reimcode">
                            <cfif reimcode eq reserveword>
                                <cfset LOCAL.reimintfcurr = qReimInterface.currency_code[no]>
    
                                <cfif reimintfcurr eq qCurrCodeAllDed.currency_code>
                                    <cfset LOCAL.compvalue = compvalue + qReimInterface.total[no]>
                                <cfelse>
                                    <cfquery name="LOCAL.qConvert" datasource="#REQUEST.SDSN#">
                                        <cfif request.dbdriver eq "MSSQL">
                                            SELECT * FROM
                                            dbo.sfconvertcurrency(#qReimInterface.total[no]#,'#reimintfcurr#','#qCurrCodeAllDed.currency_code#',#request.scookie.coid#,getdate(),'CURR')
                                        <cfelseif request.dbdriver eq "MYSQL">
                                            SELECT SUBSTRING_INDEX(sfconvertcurrency(#qReimInterface.total[no]#,'#reimintfcurr#','#qCurrCodeAllDed.currency_code#',#request.scookie.coid#,NOW(),'CURR'),'|',1) AS CONVERTRESULT
                                        </cfif>
                                    </cfquery>
    
                                    <cfset LOCAL.compvalue = compvalue + qConvert.CONVERTRESULT>
                                </cfif>
                            </cfif>
    
                            <cfset no = no + 1>
                        </cfloop>
                    <cfelseif reswordcategory eq "LEAVEGRADEENT">  <--- mark --->
                        <cfset LOCAL.leavegrade_code = qLeaveGrade.leavegrade_code>
                        <cfset LOCAL.compvalue = 0>
        
                        <!---
                        <cfquery name="LOCAL.qTruncateTemp" datasource="#REQUEST.SDSN#">
                            TRUNCATE TABLE TTADEMPLEAVEENTTEMP
                        </cfquery>
        
                        <cfquery name="LOCAL.qInsertTemp" datasource="#REQUEST.SDSN#">
                            INSERT INTO TTADEMPLEAVEENTTEMP (leave_grade, emp_id, effective_date)
                            SELECT leave_grade, emp_id, effective_date FROM (
                                SELECT DISTINCT TTARLEAVEENTGRADE.leave_grade, emp_id, TTADEMPLEAVEGRADE.effective_date
                                    FROM TTADEMPLEAVEGRADE,TTAMLEAVEENT, TTARLEAVEENTGRADE
                                    WHERE TTADEMPLEAVEGRADE.effective_date >= TTAMLEAVEENT.effective_date
                                        AND TTAMLEAVEENT.leave_code = TTARLEAVEENTGRADE.leave_code
                                        AND TTADEMPLEAVEGRADE.leavegrade_code = TTARLEAVEENTGRADE.leave_grade
                                        AND TTAMLEAVEENT.leave_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.periodcode#">
                                        AND TTADEMPLEAVEGRADE.emp_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                                        AND TTADEMPLEAVEGRADE.company_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#request.scookie.cocode#">
                            ) TABLETEMP
                        </cfquery>
        
        
                        <cfquery name="LOCAL.qProportional" datasource="#REQUEST.SDSN#" >
                            SELECT proportional_flag
                            FROM TTAMLEAVEENT
                            WHERE leave_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.periodcode#">
                        </cfquery>
        
                        <cfquery name="LOCAL.qLimitDate" datasource="#REQUEST.SDSN#" >
                            SELECT field_value FROM TCLCAPPCOMPANY WHERE field_code = 'proratelimitdate'
                        </cfquery>--->
        
                        <cfquery name="LOCAL.qJoinDate" datasource="#REQUEST.SDSN#">
                            SELECT start_date, end_date FROM TEODEMPCOMPANY
                            WHERE emp_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.empid#">
                            AND company_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.companyid#">
                        </cfquery>
        
                        <!---
                        <cfif Day(qJoinDate.start_date) gt qLimitDate.field_value>
                            <cfset LOCAL.Join_Date = DateAdd("m",1,qJoinDate.start_date)>
                            <cfset Join_Date = CreateDate(Year(Join_Date), Month(Join_Date), 1)>
                        <cfelse>
                            <cfset LOCAL.Join_Date = CreateODBCDate(CreateDate(year(qJoinDate.start_date), month(qJoinDate.start_date), 1))>
                        </cfif>
        
                        <cfif isdate(qJoinDate.end_date) and datecompare(qJoinDate.end_date,now()) lt 0>
                          <cfset local.enddateemp = qJoinDate.end_date>
                        <cfelse>
                            <cfset local.enddateemp = now()>
                        </cfif>--->
        
                        <cfif isdate(qJoinDate.end_date) and datecompare(qJoinDate.end_date,arguments.paydate) lt 0>
                          <cfset local.enddateemp = qJoinDate.end_date>
                        <cfelse>
                            <cfset local.enddateemp = arguments.paydate>
                        </cfif>
        
                        <!---
                        <cfset LOCAL.Join_Date_CurrYear = CreateDate(Year(Now()),Month(Join_Date),Day(Join_Date))>
                        <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveGradeEntTemp">
                            SELECT order_no, effective_date, leave_grade
                                FROM TTADEMPLEAVEENTTEMP
                                ORDER BY effective_date ASC
                        </cfquery>
                        <cfloop query="qLeaveGradeEntTemp">
                            <cfif qLeaveGradeEntTemp.effective_date lt CreateDate(Year(Now()), 1, 1)>
                                <cfquery name="LOCAL.qryUpdateLeaveEntitlement" datasource="#REQUEST.SDSN#">
                                    UPDATE  TTADEMPLEAVEENTTEMP
                                    SET     effective_date = <cfqueryparam value="#CreateDate(Year(Now()), 1, 1)#" cfsqltype="CF_SQL_TIMESTAMP"/>
                                    WHERE   order_no = <cfqueryparam value="#qLeaveGradeEntTemp.order_no#" cfsqltype="CF_SQL_INTEGER"/>
                                </cfquery>
                            </cfif>
                        </cfloop>--->
        
                        <cfset local.losemp = INT(DateDiff("m",qJoinDate.start_date,local.enddateemp)/12)>
        
                        <!---
                        <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveGradeEntTemp">
                            SELECT order_no, effective_date, leave_grade
                                FROM TTADEMPLEAVEENTTEMP
                                ORDER BY effective_date ASC
                        </cfquery>--->
                        <cfquery name="LOCAL.qcekEnt" datasource="#REQUEST.SDSN#">
                            SELECT entitlement, lengthofservice
                            FROM TTARLEAVEENTGRADE
                            WHERE TTARLEAVEENTGRADE.leave_grade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#LOCAL.leavegrade_code#">
                            AND Leave_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.periodcode#">
                            ORDER BY lengthofservice
                        </cfquery>
        
                        <!---
                        <cfif qLeaveGradeEntTemp.RecordCount gt 1>
                            <cfloop query="qLeaveGradeEntTemp" startrow="1" endrow="#qLeaveGradeEntTemp.RecordCount-1#">
                                <cfif qLeaveGradeEntTemp.effective_date[CurrentRow+1] gt Join_Date_CurrYear>
                                    <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveGradeEntTemp">
                                        INSERT INTO TTADEMPLEAVEENTTEMP (leave_grade,emp_id, effective_date, flag_Anniversary)
                                        VALUES ('#qLeaveGradeEntTemp.leave_grade#','#arguments.empid#', #Join_Date_CurrYear#, '1')
                                    </cfquery>
                                    <cfbreak>
                                </cfif>
                            </cfloop>
                        <cfelseif qLeaveGradeEntTemp.RecordCount eq 1>
                            <cfif Join_Date_CurrYear gt qLeaveGradeEntTemp.effective_date>
                                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveGradeEntTemp">
                                    INSERT INTO TTADEMPLEAVEENTTEMP (leave_grade, emp_id, effective_date, flag_Anniversary)
                                    VALUES ('#qLeaveGradeEntTemp.leave_grade#','#arguments.empid#', #Join_Date_CurrYear#, '1')
                                </cfquery>
                            </cfif>
                        </cfif>
                        --->
                        <cfset LOCAL.Value =0>
    
                        <cfloop query="qcekEnt">
                            <cfif losemp gte qcekEnt.lengthofservice and losemp lt qcekEnt.lengthofservice[currentrow+1]>
                                <cfset LOCAL.Value = qcekEnt.entitlement><cfbreak>
                            <cfelseif qcekEnt.currentrow eq qcekEnt.recordcount and losemp gt qcekEnt.lengthofservice>
                                <cfset LOCAL.Value = qcekEnt.entitlement[currentrow]>
                            </cfif>
                        </cfloop>
                        <!---
                        <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveGradeEntTemp">
                            SELECT order_no, effective_date, leave_grade
                                FROM TTADEMPLEAVEENTTEMP
                                ORDER BY effective_date ASC
                        </cfquery>
        
                        <cfloop query="qLeaveGradeEntTemp">
                            <cfquery name="LOCAL.qUpdateLeaveGradeEntTemp" datasource="#REQUEST.SDSN#">
                                <cfif qLeaveGradeEntTemp.CurrentRow lt qLeaveGradeEntTemp.RecordCount>
                                    UPDATE  TTADEMPLEAVEENTTEMP
                                    SET     End_Date = <cfqueryparam value="#DateAdd("d", -1, qLeaveGradeEntTemp.effective_date[qLeaveGradeEntTemp.CurrentRow+1])#" cfsqltype="CF_SQL_TIMESTAMP"/>
                                    WHERE   order_no = <cfqueryparam value="#qLeaveGradeEntTemp.order_no#" cfsqltype="CF_SQL_INTEGER" />
                                <cfelse>
                                    UPDATE  TTADEMPLEAVEENTTEMP
                                    SET     End_Date = <cfqueryparam value="#CreateDate(Year(qLeaveGradeEntTemp.effective_date[qLeaveGradeEntTemp.CurrentRow]), 12, 31)#" cfsqltype="CF_SQL_TIMESTAMP"/>
                                    WHERE   order_no = <cfqueryparam value="#qLeaveGradeEntTemp.order_no#" cfsqltype="CF_SQL_INTEGER"/>
                                </cfif>
                            </cfquery>
                        </cfloop>
        
                        <cfif qJoinDate.End_Date neq "">
                            <cfif qJoinDate.End_Date gt CreateDate(Year(now())+1, 1, 1)>
                                <cfset LOCAL.DateEnd = CreateDate(Year(now())+1, 1, 1)>
                            <cfelse>
                                <cfset LOCAL.DateEnd = DateAdd("d",1,CreateDate(Year(qJoinDate.End_Date), Month(qJoinDate.End_Date), DaysInMonth(qJoinDate.End_Date)))>
                            </cfif>
                        <cfelse>
                            <cfset LOCAL.DateEnd = CreateDate(Year(now())+1, 1, 1)>
                        </cfif>
        
                        <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveGradeEntTemp">
                            SELECT Order_No, leave_grade, effective_date, end_date, flag_anniversary
                                FROM TTADEMPLEAVEENTTEMP
                                WHERE year(End_Date) >= <cfqueryparam value="#Year(Now())#" cfsqltype="CF_SQL_INTEGER"/>
                                AND effective_date <= <cfqueryparam value="#CreateODBCDate(DateEnd)#" cfsqltype="CF_SQL_TIMESTAMP"/>
                                ORDER BY effective_date ASC
                        </cfquery>
                        <cfset LOCAL.Value = 0>
        
                        <cfset LOCAL.yearServices = datediff("yyyy",Join_Date,DateEnd)>
                        <cfloop query="LOCAL.qLeaveGradeEntTemp">
                            <cfset LOCAL.Value1 = 0>
                            <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveLosEnt">
                                SELECT lengthofservice, entitlement
                                FROM TTARLEAVEENTGRADE
                                WHERE leave_code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.periodcode#">
                                AND leave_grade = <cfqueryparam value="#qLeaveGradeEntTemp.leave_grade#" cfsqltype="CF_SQL_VARCHAR">
                                ORDER BY lengthofservice DESC
                            </cfquery>
                            <cfloop query="qLeaveLosEnt">
                                <cfif qLeaveGradeEntTemp.flag_anniversary neq 1>
                                    <cfif (yearServices gt  qLeaveLosEnt.lengthofservice) OR (yearServices eq 0)>
                                            <cfif Day(qLeaveGradeEntTemp.effective_date) lte qLimitDate.field_value>
                                                <cfset LOCAL.EffectiveDate = CreateDate(Year(qLeaveGradeEntTemp.effective_date), Month(qLeaveGradeEntTemp.effective_date), 1)>
                                            <cfelse>
                                                <cfset LOCAL.EffectiveDate = CreateDate(Year(qLeaveGradeEntTemp.effective_date), Month(qLeaveGradeEntTemp.effective_date)+1, 1)>
                                            </cfif>
                                            <cfif Day(qLeaveGradeEntTemp.end_date) gte qLimitDate.field_value>
                                                <cfset LOCAL.EndDate = DateAdd("d",1,CreateDate(Year(qLeaveGradeEntTemp.end_date), Month(qLeaveGradeEntTemp.end_date), DaysInMonth(qLeaveGradeEntTemp.end_date)))>
                                            <cfelse>
                                                <cfset LOCAL.EndDate = CreateDate(Year(qLeaveGradeEntTemp.end_date), Month(qLeaveGradeEntTemp.end_date), 1)>
                                            </cfif>
                                            <cfif EndDate gt DateEnd>
                                                <cfset LOCAL.EndDate = DateEnd>
                                            </cfif>
                                            <cfset LOCAL.Value1 = Value1 + (DateDiff("m", EffectiveDate, EndDate) / 12 * qLeaveLosEnt.entitlement)>
                                            <cfbreak>
                                    </cfif>
                                <cfelse>
                                    <cfif yearServices gte  qLeaveLosEnt.lengthofservice>
                                            <cfif Day(qLeaveGradeEntTemp.effective_date) lte qLimitDate.field_value>
                                                <cfset LOCAL.EffectiveDate = CreateDate(Year(qLeaveGradeEntTemp.effective_date), Month(qLeaveGradeEntTemp.effective_date), 1)>
                                            <cfelse>
                                                <cfset LOCAL.EffectiveDate = CreateDate(Year(qLeaveGradeEntTemp.effective_date), Month(qLeaveGradeEntTemp.effective_date)+1, 1)>
                                            </cfif>
                                            <cfif Day(qLeaveGradeEntTemp.end_date) gte qLimitDate.field_value>
                                                <cfset LOCAL.EndDate = DateAdd("d",1,CreateDate(Year(qLeaveGradeEntTemp.end_date), Month(qLeaveGradeEntTemp.end_date), DaysInMonth(qLeaveGradeEntTemp.end_date)))>
                                            <cfelse>
                                                <cfset LOCAL.EndDate = CreateDate(Year(qLeaveGradeEntTemp.end_date), Month(qLeaveGradeEntTemp.end_date), 1)>
                                            </cfif>
                                            <cfif EndDate gt DateEnd>
                                                <cfset LOCAL.EndDate = DateEnd>
                                            </cfif>
                                            <cfset LOCAL.Value1 =  Value1 + (DateDiff("m", EffectiveDate, EndDate) / 12 * qLeaveLosEnt.entitlement)>
        
                                            <cfbreak>
                                    </cfif>
                                </cfif>
                            </cfloop>
                            <cfset LOCAL.Value = Value + Value1>
                        </cfloop>--->
                        <cfif reserveword eq 'LEAVEENTITLEMENTTABLE'>
                            <cfset LOCAL.compvalue = local.Value>
                        <cfelseif reserveword eq 'LEAVEGRADE'>
                            <cfset LOCAL.compvalue = leavegrade_code>
                        </cfif>
                    <cfelseif reswordcategory eq "LEAVEBALANCE">  <--- mark --->
                        <cfif ListFirst(reserveword,"_") eq 'REMAIN'>
                            <cfset LOCAL.compvalue = RemainLeaveBalance(arguments.empid,reserveword)>
                        <cfelseif ListLast(reserveword,"_") eq 'REMAINS'>
                            <cfset LOCAL.compvalue = LeaveBalanceRemains(arguments.empid,reserveword)>
                        <cfelseif ListLast(reserveword,"_") eq 'TOTALDAY'>
                            <cfset LOCAL.compvalue = LeaveBalanceTotalDay(arguments.empid,reserveword,'#paydate#')>
                        <cfelseif ListLast(reserveword,"_") eq 'PROPORTIONAL'>
                            <cfset LOCAL.compvalue = LeaveBalanceProportional(arguments.empid,reserveword)>
                        <cfelseif ListLast(reserveword,"_") eq 'USED'><!---BP--->
                            <cfset LOCAL.compvalue = getCurrPrevUsed(arguments.empid,reserveword,'#paydate#')>
                        </cfif>
                    <cfelseif reswordcategory eq "PAYCOMP_MY">
                        <cfif not structKeyExists(variables, "objFormulaMY")>
                            <cfset Variables.objFormulaMY = CreateObject("component","SFFormulaMY")>
                        </cfif>
    
                        <cfset LOCAL.compvalue =  Variables.objFormulaMY.formula_my('#reserveword#','#arguments.empid#','#arguments.periodcode#',arguments.companyid)>
                    <cfelseif reswordcategory eq "PAYCOMP_TH"> <!--- PFEMPLOYEE, PFEMPLOYER--->
                        <cfif not structKeyExists(variables, "objFormulaTH")>
                            <cfset Variables.objFormulaTH = CreateObject("component","SFFormulaTH")>
                        </cfif>
    
                        <cfset LOCAL.compvalue =  Variables.objFormulaTH.formula_th('#reserveword#','#arguments.empid#','#arguments.periodcode#',arguments.companyid,'#paydate#')>
                    <cfelseif reswordcategory eq "PAYCOMP_SG">
                        <cfif not structKeyExists(variables, "objFormulaSG")>
                            <cfset Variables.objFormulaSG = CreateObject("component","SFFormulaSG")>
                        </cfif>
    
                        <cfset LOCAL.compvalue =  Variables.objFormulaSG.formula_sg('#reserveword#','#arguments.empid#','#arguments.periodcode#',arguments.companyid)>
                    <cfelseif reswordcategory eq "PAYCOMP_PH">
                        <!---<cfoutput>formula_ph LOCAL.reserveword: #LOCAL.reserveword#<br></cfoutput>--->
                        <cfif not structKeyExists(variables, "objFormulaPH")>
                            <cfset Variables.objFormulaPH = CreateObject("component","SFFormulaPH")>
                        </cfif>
    
                        <cfset LOCAL.compvalue =  Variables.objFormulaPH.formula_ph('#LOCAL.reserveword#','#arguments.empid#','#arguments.periodcode#',arguments.companyid,'#paydate#')>
                    <cfelseif reswordcategory eq "PAYCOMP_ID">
                         <cfset LOCAL.compvalue = 0>
                        <cfif reserveword eq 'RELBPJSTK'>
                            <cfset LOCAL.compvalue = getrelbpjstk(
                                                                    empid=arguments.empid
                                                                    ,periodcode=arguments.periodcode
                                                                    ,paydate=arguments.paydate
                                                                )>
                        </cfif>
                    <cfelseif reswordcategory eq "CUSTOM">
                        <cfif not structKeyExists(variables, "objFormulaCustom")>
                            <cfset Variables.objFormulaCustom = CreateObject("component","SFFormulaCustom")>
                        </cfif>
    
                        <cfset LOCAL.compvalue = Variables.objFormulaCustom.getValue('#reserveword#','#arguments.empid#',arguments.companyid,'#arguments.paydate#','#arguments.periodcode#','#arguments.lookupperiod#','#arguments.flagreim#','#arguments.allowdeduct_code#','#arguments.attendid#','#arguments.empfamily_id#',arguments.totalcost,arguments.isReturnStruct)>
    
                        <cfif not isdefined("local.compvalue")> 
                            <cfset Local.compvalue = "">
    
                            <cfif arguments.periodcode neq "">                      
                                <cfheader
                                statuscode="400"
                                statustext="Invalid Reserveword"
                                />
                                <cfoutput>Invalid Custom Reserveword</cfoutput>
                                <CF_SFABORT>
                                <cfset Local.error = "<DATA><PROCESS_DETAIL><DATA><STATUS>0</STATUS><ERROR>Invalid Custom Reserveword #reserveword#</ERROR></DATA></PROCESS_DETAIL></DATA>">
                                <cfoutput>#Local.error#</cfoutput>                      
                            </cfif>
                        </cfif>
                    <cfelseif reswordcategory eq "CAREERDATA">
                        <cfif reserveword eq "LENGTHOFSERVICE_RESET">
                            <cfquery name="Local.qCalculateLOS" datasource="#REQUEST.SDSN#">
                                <cfif request.dbdriver eq "MSSQL">
                                    select dbo.CalculateLOS('#arguments.empid#',#arguments.companyid#) as los
                                <cfelseif request.dbdriver eq "MYSQL">
                                    select CalculateLOS('#arguments.empid#',#arguments.companyid#) as los from dual
                                </cfif>
                            </cfquery>
    
                            <cfif Local.qCalculateLOS.los neq '' >
                                <cfset LOCAL.compvalue = #Local.qCalculateLOS.los#>
                            </cfif>
                        </cfif>
                    <!--- start TCK1910-0528790 --->
                    <cfelseif reswordcategory eq "ATTENDHOLIDAY">  <--- mark --->
                        <cfif reserveword eq "HOLIDAYTYPE">
                            <cfset var objSFAttendance = CreateObject("component","SFAttendance")>
                            <cfset var qCekHoliday = objSFAttendance.getHoliday(arguments.paydate,arguments.empid,arguments.companyid)>
    
                            <cfif qCekHoliday.recordcount>
                                <cfif qCekHoliday.holiday_type eq 2>
                                    <cfset LOCAL.compvalue = "SPECIALDAY">
                                <cfelse>
                                    <cfset LOCAL.compvalue = "PUBLIC">
                                </cfif>
                            </cfif>
                        </cfif>
                    <!--- end TCK1910-0528790 --->
                    </cfif>
                    <cfif reswordtype eq "DATE" and local.compvalue neq "">
                        <cfset LOCAL.compvalue = DATEFORMAT(LOCAL.compvalue,"MM/DD/YYYY")>
                    <cfelseif reswordtype eq "VARCHAR" and local.compvalue neq "">
                    <cfelseif local.compvalue eq "">
                        <cfset LOCAL.compvalue = 0>
                    </cfif>
                <cfelse>
                    <cfset LOCAL.compvalue = 0>
                </cfif>
    
                <cfset lstresult = ListAppend(lstresult,local.compvalue,"~")>
                <cfset scReturn[reserveword]=compvalue>
            </cfloop>
        
            <cfif Arguments.isReturnStruct>
                <cfset lstresult=listMerge(lstresult,REQUEST.EVALWORD[valKey].lstresult)>
                <cfset scReturn.lstresult=lstresult>
                
                <cfloop index="LOCAL.ikey" list="#StructKeyList(scReturn)#">
                    <cfset REQUEST.EVALWORD[valKey][ikey]=scReturn[ikey]>
                </cfloop>
                <cfloop index="LOCAL.ikey" list="#Arguments.lstreserveword#">
                    <cfif not StructKeyExists(scReturn,ikey) and StructKeyExists(REQUEST.EVALWORD[valKey],ikey)>
                        <cfset scReturn[ikey]=REQUEST.EVALWORD[valKey][ikey]>
                    </cfif>
                </cfloop>
    
                <cfreturn scReturn>
            <cfelse>
                <cfreturn lstresult>
            </cfif>
        </cffunction>
    
    
        <cffunction name="InitValue">
            <cfargument name="lstreserveword" default="">
            <cfargument name="empid" default="">
            <cfargument name="companyid" default="#request.scookie.coid#">
            <cfargument name="paydate" default="#now()#">
            <cfargument name="periodcode" default="">
            <cfargument name="attendid" default="">
            <cfargument name="empfamily_id" default="">
    
            <cfargument name="startdatePeriod" default="">
            <cfargument name="enddatePeriod" default="">
            
            <cfset LOCAL.objFormula = createobject("component","SFFormula")/>
        
            <cfset LOCAL.scRetVar={QUERY={}}>
            <cfset LOCAL.company_code = #request.scookie.cocode# >
            
            <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qResWord" >
                SELECT ltrim(rtrim(word)) word, category, data_type FROM TSFMRESERVEWORD
                WHERE company_id IN (<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#,1" list="yes">)
                AND word IN (#ListQualify(replace(replace(Arguments.lstreserveword,'@','','All'),'$','','ALL'),"'",",")#)
                ORDER BY category
            </cfquery>
            
            <cfset scRetVar.QUERY.qResWord=qResWord>
            
            <cfquery dbtype="query" name="LOCAL.qResWordCategory" >
                SELECT category FROM qResWord
                group BY category
            </cfquery>
            
            <cfset LOCAL.lstreswordcategory = valueList(qResWordCategory.category)>
            <!---<cfoutput><script>logthis("#lstreswordcategory#");</script></cfoutput>--->
            <cfif ListFindNoCase(lstreswordcategory,"EMPDATA")>
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qEmpData">
                    SELECT TEODEMPCOMPANY.Emp_No as EMPNO, TEODEMPCOMPANY.Grade_Code as GRADE, TEODEMPCOMPANY.Employ_Code as EMPLOYMENTSTATUS,
                        TEODEMPCOMPANY.Start_Date as STARTDATE, TEODEMPCOMPANY.End_Date as ENDDATE,
                        TEOMGRADECATEGORY.GradeCategory_Code as GRADECAT, TEODEMPCOMPANY.Job_Status_Code as JOBSTATUS, TEODEMPCOMPANY.cost_code as COSTCENTER,
                        TEODEMPCOMPANY.work_location_code as WORKLOCATION,
                        TEOMWORKLOCATION.worklocation_type as WORKLOCATIONTYPE, <!---ENC51016-80649--->
                        TEOMPOSITION.pos_name_en as POSITIONNAME, TEOMPOSITION.pos_Code as POSITION,
                        DIVLOOK.pos_code as DIVISION , DIVLOOK.pos_name_en as DIVISIONNAME,
                        TEOMEMPPERSONAL.gender, TEODEMPCOMPANYGROUP.join_date as JOINDATE, TEODEMPCOMPANYGROUP.permanent_date as PERMANENTDATE,
                        TEODEMPCOMPANYGROUP.fulljoin_date as FULLJOINDATE, TEODEMPCOMPANYGROUP.prepension_date as PREPENSIONDATE,
                        TEODEMPCOMPANYGROUP.pension_date as PENSIONDATE, TEODEMPCOMPANYGROUP.terminate_date as TERMINATEDATE,
                        TEODEMPCOMPANYGROUP.terminate_reason as RESIGNREASON, TEODEMPCOMPANYGROUP.resignation,
                        TEOMPOSITION.jobtitle_code as JOBTITLE, <!--- TCK1910-0527891 --->
                        TEORJFL.jfl_name_en as JOBFAMILYLEVEL <!---17032021| add for TCK2103-0632731--->
                    FROM TEODEMPCOMPANY
                        INNER JOIN TEOMEMPPERSONAL ON TEOMEMPPERSONAL.emp_id = TEODEMPCOMPANY.emp_id
                        INNER JOIN TEODEMPCOMPANYGROUP ON TEODEMPCOMPANYGROUP.emp_id = TEODEMPCOMPANY.emp_id
                        INNER JOIN TEOMJOBGRADE ON TEOMJOBGRADE.grade_code = TEODEMPCOMPANY.grade_code
                            AND TEOMJOBGRADE.company_id = TEODEMPCOMPANY.company_id
                        LEFT JOIN TEOMGRADECATEGORY ON TEOMGRADECATEGORY.gradecategory_Code = TEOMJOBGRADE.gradecategory_code
                            AND TEOMJOBGRADE.company_id = TEOMGRADECATEGORY.company_id
                        INNER JOIN TEOMPOSITION ON TEOMPOSITION.position_id = TEODEMPCOMPANY.position_id
                            AND TEOMPOSITION.company_id = TEODEMPCOMPANY.company_id
                        LEFT JOIN TEOMPOSITION DIVLOOK ON DIVLOOK.position_id = TEOMPOSITION.dept_id
                            AND TEOMPOSITION.company_id = DIVLOOK.company_id
                        LEFT JOIN TEOMWORKLOCATION ON TEOMWORKLOCATION.worklocation_code = TEODEMPCOMPANY.work_location_code
                            AND TEOMWORKLOCATION.company_id = TEODEMPCOMPANY.company_id <!---ENC51016-80649--->
                        LEFT JOIN TEOMJOBTITLE ON TEOMJOBTITLE.jobtitle_code = TEOMPOSITION.jobtitle_code <!---17032021| add for TCK2103-0632731--->
                        LEFT JOIN TEORJFL ON TEORJFL.jfl_code = TEOMJOBTITLE.jfl_code <!---17032021| add for TCK2103-0632731--->
                    WHERE TEODEMPCOMPANY.company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                    AND TEODEMPCOMPANY.EMP_ID = <CFQUERYPARAM VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                </cfquery>
    
                <cfset scRetVar.QUERY.qEmpData=qEmpData>
            </cfif>
            
            <cfif ListFindNoCase(lstreswordcategory,"EMPDATAHISTORY")>
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qEmpDataHistoryProrate" maxrows="1">
                    SELECT 
                        emp_no as EMPNO_HIST,
                        position_code as POSITION_HIST,
                        employmentstatus_code as EMPLOYMENTSTATUS_HIST,
                        grade_code as GRADE_HIST,
                        costcenter_code as COSTCENTER_HIST,
                        worklocation_code as WORKLOCATION_HIST,
                        jobstatus_code as JOBSTATUS_HIST
                    from TEODEMPLOYMENTHISTORY
                    WHERE company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                    AND emp_id= <CFQUERYPARAM VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    AND effectivedt <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                    ORDER BY effectivedt DESC
                </cfquery>
    
                <cfset scRetVar.QUERY.qEmpDataHistoryProrate=qEmpDataHistoryProrate>
            </cfif>
            
            <cfif ListFindNoCase(lstreswordcategory,"EMPHISTORY_DIEPVU")>
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qEmpDiepVu">
                    <cfif request.dbdriver eq "ORACLE">
                        SELECT EFFECTIVEDT
                        FROM (
                            SELECT
                                TEODEMPLOYMENTHISTORY.EFFECTIVEDT
                            FROM TEODEMPCOMPANY
                                INNER JOIN TEODEMPLOYMENTHISTORY ON TEODEMPCOMPANY.EMP_ID = TEODEMPLOYMENTHISTORY.EMP_ID
                                INNER JOIN TEOMPOSITION ON TEODEMPCOMPANY.POSITION_ID = TEOMPOSITION.POSITION_ID
                            WHERE TEODEMPCOMPANY.company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                            AND TEODEMPCOMPANY.EMP_ID = <CFQUERYPARAM VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                            <!--- AND TEODEMPLOYMENTHISTORY.POSITION_CODE = '10131111' ---><!--- sewing position --->
                            AND TEODEMPCOMPANY.POSITION_ID = TEOMPOSITION.POSITION_ID
                            AND TEOMPOSITION.POS_CODE = TEODEMPLOYMENTHISTORY.POSITION_CODE
                            ORDER BY TEODEMPLOYMENTHISTORY.EFFECTIVEDT ASC
                        ) H
                        WHERE
                        ROWNUM < 2
                    <cfelse>
                        SELECT
                            TOP 1 TEODEMPLOYMENTHISTORY.EFFECTIVEDT
                        FROM TEODEMPCOMPANY
                            INNER JOIN TEODEMPLOYMENTHISTORY ON TEODEMPCOMPANY.EMP_ID = TEODEMPLOYMENTHISTORY.EMP_ID
                            INNER JOIN TEOMPOSITION ON TEODEMPCOMPANY.POSITION_ID = TEOMPOSITION.POSITION_ID
                        WHERE TEODEMPCOMPANY.company_id = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#arguments.companyid#">
                        AND TEODEMPCOMPANY.EMP_ID = <CFQUERYPARAM VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                        <!--- AND TEODEMPLOYMENTHISTORY.POSITION_CODE = '10131111' ---><!--- sewing position --->
                        AND TEODEMPCOMPANY.POSITION_ID = TEOMPOSITION.POSITION_ID
                        AND TEOMPOSITION.POS_CODE = TEODEMPLOYMENTHISTORY.POSITION_CODE
                        ORDER BY TEODEMPLOYMENTHISTORY.EFFECTIVEDT ASC
                    </cfif>
                </cfquery>
                
                <cfset scRetVar.QUERY.qEmpDiepVu=qEmpDiepVu>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"EMPPERSONAL")><!--- EMPPERSONAL : TEODEMPPERSONAL, TEODEMPADDRESS, TEODEMPEDUCATION, dsb [table terkait data personal employee] --->
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qEmpPersonal" >
                    SELECT TEODEMPPERSONAL.birthdate, TEODEMPPERSONAL.religion_code as RELIGION, TEODEMPPERSONAL.maritalstatus,TEOMEMPPERSONAL.GENDER
                        <cfif request.dbdriver eq "ORACLE">
                            ,FLOOR(MONTHS_BETWEEN(#arguments.paydate#,TEODEMPPERSONAL.birthdate)/12) AS age
                        <cfelse>
                            ,#Application.SFUtil.DBDateDiff("year","TEODEMPPERSONAL.birthdate","#arguments.paydate#")# AS age
                            <!---,FLOOR(DATEDIFF(YEAR,TEODEMPPERSONAL.birthdate,#arguments.paydate#)) AS age--->
                        </cfif>
                    FROM TEODEMPPERSONAL
                    INNER JOIN TEOMEMPPERSONAL ON TEOMEMPPERSONAL.EMP_ID=TEODEMPPERSONAL.EMP_ID
                    WHERE TEODEMPPERSONAL.EMP_ID = <CFQUERYPARAM VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                </cfquery>
    
                <!---define kembali age menggunakan coding CF, karena berbeda hasil antara mssql dan maria--->
                <cfset qEmpPersonal.age = datediff("yyyy",'#qEmpPersonal.birthdate#','#arguments.paydate#')>
                <cfset scRetVar.QUERY.qEmpPersonal=qEmpPersonal>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"CUSTOMFIELD")><!--- CUSTOMFIELD : TEODEMPCUSTOMFIELD [Employee Custom Field]--->
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qEmpCustomField" >
                    SELECT *
                    FROM TEODEMPCUSTOMFIELD
                    WHERE TEODEMPCUSTOMFIELD.EMP_ID = <CFQUERYPARAM VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                </cfquery>
    
                <cfset scRetVar.QUERY.qEmpCustomField=qEmpCustomField>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"ATTENDREQUEST")> <!--- Attendance Request : Onduty Request, Overtime Request, Leave Request --->
                <cfif FindNoCase("ONDUTY",lstreserveword)>
                    <cfquery name="LOCAL.qOnduty" datasource="#REQUEST.SDSN#">
                        SELECT TTADONDUTYREQUEST.request_no
                        FROM TTADONDUTYREQUEST
                            INNER JOIN TTADONDUTYREQUESTDTL ON TTADONDUTYREQUESTDTL.request_no = TTADONDUTYREQUEST.request_no
                                AND TTADONDUTYREQUEST.company_id = TTADONDUTYREQUESTDTL.company_id
                            INNER JOIN TCLTREQUEST ON TTADONDUTYREQUEST.request_no = TCLTREQUEST.req_no
                                AND TTADONDUTYREQUEST.company_id = TCLTREQUEST.company_id
                        WHERE TTADONDUTYREQUEST.requestfor = <CFQUERYPARAM VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                        AND TTADONDUTYREQUESTDTL.startdate >= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                        AND TTADONDUTYREQUESTDTL.enddate < <cfqueryparam value="#CreateODBCDate(DateAdd("d",1,arguments.paydate))#" cfsqltype="CF_SQL_TIMESTAMP">
                        AND TCLTREQUEST.status = 3
                    </cfquery>
    
                    <cfset scRetVar.QUERY.qOnduty=qOnduty>
                </cfif>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"ATTENDDATA")><!--- ATTENDDATA : TTADATTENDANCE, TTADATTBREAK, TTADATTSTATUSDETAIL, TTADATTOVTDETAIL [table attendance harian/detail attendance record]--->
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qAttendData">
                    SELECT TTADATTENDANCE.shiftdaily_code, TTADATTENDANCE.attend_code, TTADATTENDANCE.daytype, TTADATTENDANCE.default_shift, TTADATTENDANCE.flexibleshift,
                    <cfif UCase(REQUEST.DBDriver) EQ "MSSQL">
                            dbo.sfattstatusdetail(TTADATTENDANCE.attend_id,'')
                        <cfelse>
                            sfattstatusdetail(TTADATTENDANCE.attend_id,'')
                        </cfif> lstattendsts,
                        TSHIFTGROUP.shiftgroupcode, TTADATTENDANCE.starttime,TTADATTENDANCE.endtime, TTADATTENDANCE.shiftstarttime, TTADATTENDANCE.shiftendtime, TTADATTENDANCE.total_ot total_ovt
                        , TTADATTENDANCE.actual_in, TTADATTENDANCE.actual_out, TTADATTENDANCE.actualworkmnt, TTADATTENDANCE.flexibleshift, TTADATTENDANCE.overtime_code, TTADATTENDANCE.actual_lti as ACTUALLTI, TTADATTENDANCE.actual_eao as ACTUALEAO, TTADATTENDANCE.total_otindex as OTINDEX
                    FROM TTADATTENDANCE
                    INNER JOIN (
                        <cfif request.dbdriver eq "ORACLE">
                            SELECT emp_id, shiftgroupcode FROM (
                                SELECT emp_id, shiftgroupcode FROM TTADEMPSHIFTGROUP
                                WHERE TTADEMPSHIFTGROUP.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                    AND company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                                    AND startshiftdate <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                                ORDER BY startshiftdate DESC
                            ) a WHERE ROWNUM < 2
                        <cfelseif request.dbdriver eq "MSSQL">
                            SELECT TOP 1 emp_id, shiftgroupcode FROM TTADEMPSHIFTGROUP
                            WHERE TTADEMPSHIFTGROUP.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                                AND startshiftdate <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                            ORDER BY startshiftdate DESC
                        <cfelseif request.dbdriver eq "MYSQL">
                            SELECT  emp_id, shiftgroupcode FROM TTADEMPSHIFTGROUP
                            WHERE TTADEMPSHIFTGROUP.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                AND company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                                AND startshiftdate <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                            ORDER BY startshiftdate DESC
                            LIMIT 1
                        </cfif>
                    ) TSHIFTGROUP ON TSHIFTGROUP.emp_id = TTADATTENDANCE.emp_id
                    WHERE TTADATTENDANCE.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    and TTADATTENDANCE.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                    <cfif arguments.attendid neq "">
                    and TTADATTENDANCE.attend_id = <cfqueryparam VALUE="#arguments.attendid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    </cfif>
                    and TTADATTENDANCE.shiftstarttime >= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                    and TTADATTENDANCE.shiftstarttime < <cfqueryparam value="#CreateODBCDate(dateadd("d",1,arguments.paydate))#" cfsqltype="CF_SQL_TIMESTAMP"/>
                    ORDER BY TTADATTENDANCE.default_shift desc
                </cfquery>
                
                <cfset scRetVar.QUERY.qAttendData=qAttendData>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"BREAKDATA")><!--- TTADATTBREAK [table attendance harian/detail attendance record]--->
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qBreakData" maxrows="1">
                    SELECT shift_breakstart, shift_breakend, break_start, break_end, break_no
                    FROM TTADATTBREAK
                    LEFT JOIN TTADATTENDANCE ON TTADATTBREAK.attend_id = TTADATTENDANCE.attend_id AND TTADATTBREAK.company_id = TTADATTENDANCE.company_id
                    <cfif arguments.attendid neq "">
                        WHERE TTADATTBREAK.attend_id = <cfqueryparam VALUE="#arguments.attendid#" CFSQLTYPE="CF_SQL_VARCHAR">
                        and TTADATTENDANCE.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                    <cfelse>
                        WHERE TTADATTENDANCE.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                        and TTADATTENDANCE.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                        and TTADATTENDANCE.shiftstarttime >= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                        and TTADATTENDANCE.shiftstarttime < <cfqueryparam value="#CreateODBCDate(dateadd("d",1,arguments.paydate))#" cfsqltype="CF_SQL_TIMESTAMP"/>
                    </cfif>
                    ORDER BY break_no ASC
                </cfquery>
    
                <cfset scRetVar.QUERY.qBreakData=qBreakData>
            </cfif>
    
            <!---add L for enhancement formula leave setting
            <cfif ListFindNoCase(lstreswordcategory,"SYSCALC")>
                 <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qSyscalc">
                    SELECT TTADATTENDANCE.shiftdaily_code, TTADATTENDANCE.attend_code, TTADATTENDANCE.daytype, TTADATTENDANCE.default_shift, TTADATTENDANCE.flexibleshift, dbo.sfattstatusdetail(TTADATTENDANCE.attend_id,'') lstattendsts,
                        TSHIFTGROUP.shiftgroupcode, TTADATTENDANCE.starttime,TTADATTENDANCE.endtime, TTADATTENDANCE.shiftstarttime, TTADATTENDANCE.shiftendtime, TTADATTENDANCE.total_ot total_ovt
                    FROM TTADATTENDANCE
                        INNER JOIN (
                            <cfif request.dbdriver eq "ORACLE">
                                SELECT emp_id, shiftgroupcode FROM (
                                    SELECT emp_id, shiftgroupcode FROM TTADEMPSHIFTGROUP
                                    WHERE TTADEMPSHIFTGROUP.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                        AND company_id = <cfqueryparam cfsqltype="CF_SQL_NUMERIC" value="#arguments.companyid#">
                                        AND startshiftdate <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                                    ORDER BY startshiftdate DESC
                                ) a WHERE ROWNUM < 2
                            <cfelse>
                                SELECT TOP 1 emp_id, shiftgroupcode FROM TTADEMPSHIFTGROUP
                                WHERE TTADEMPSHIFTGROUP.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                                    AND company_id = <cfqueryparam cfsqltype="CF_SQL_NUMERIC" value="#arguments.companyid#">
                                    AND startshiftdate <= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                                ORDER BY startshiftdate DESC
                            </cfif>
                        ) TSHIFTGROUP ON TSHIFTGROUP.emp_id = TTADATTENDANCE.emp_id
                     WHERE TTADATTENDANCE.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    and TTADATTENDANCE.company_id = <cfqueryparam cfsqltype="CF_SQL_NUMERIC" value="#arguments.companyid#">
                    <cfif arguments.attendid neq "">
                    and TTADATTENDANCE.attend_id = <cfqueryparam VALUE="#arguments.attendid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    </cfif>
                    and TTADATTENDANCE.shiftstarttime >= <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP">
                    and TTADATTENDANCE.shiftstarttime < <cfqueryparam value="#CreateODBCDate(dateadd("d",1,arguments.paydate))#" cfsqltype="CF_SQL_TIMESTAMP"/>
                    ORDER BY TTADATTENDANCE.default_shift desc
                </cfquery>
                <cfset scRetVar.QUERY.qSyscalc=qSyscalc>
            </cfif>
            --->
            <!---end add L--->
    
            <!---add agung employee family for philipina--->
            <cfif ListFindNoCase(lstreswordcategory,"EMPPERSONALFAMILY")>
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qFamily" >
                    select empfamily_id,name,relationship,dependentsts,gender,alive_status,
                    <!---FLOOR(DATEDIFF(YEAR,birthdate,getdate())) AS age,--->
                    #Application.SFUtil.DBDateDiff("year","birthdate","#NOW()#")# age,
                    marital_status,disability,legitimate, status_goverment, company, familyemp_id
                    from  TEODEMPFAMILY
                    <!--- where empfamily_id=<cfqueryparam VALUE="#arguments.empfamily_id#" CFSQLTYPE="CF_SQL_VARCHAR"> --->
                    where emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                </cfquery>
    
                <cfset scRetVar.QUERY.qFamily=qFamily>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"ATTINTFDATA")><!--- ATTINTFDATA : TTADATTINTF, TTADATTINTFDETAIL, TTADATTINTFDETAIL_DAILY [table attendance interface]--->
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qAttIntfData">
                    SELECT TTADATTINTFDETAIL.attcomponent, TTADATTINTFDETAIL.total_value attcomponent_value, TTADATTINTFDETAIL_DAILY.total_value attcompdaily_value
                    FROM TTADATTINTF, TTADATTINTFDETAIL
                    LEFT JOIN TTADATTINTFDETAIL_DAILY
                        ON TTADATTINTFDETAIL_DAILY.attintf_id = TTADATTINTFDETAIL.attintf_id
                        AND TTADATTINTFDETAIL_DAILY.company_id = TTADATTINTFDETAIL.company_id
                        AND TTADATTINTFDETAIL_DAILY.attcomponent = TTADATTINTFDETAIL.attcomponent
                    WHERE TTADATTINTF.attintf_id = TTADATTINTFDETAIL.attintf_id
                    and TTADATTINTF.company_id = TTADATTINTFDETAIL.company_id
                    and TTADATTINTF.emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    and TTADATTINTF.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                    and TTADATTINTF.period_code = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                    and TTADATTINTF.paydate = <cfqueryparam value="#CreateODBCDate(arguments.paydate)#" cfsqltype="CF_SQL_TIMESTAMP"/>
                    ORDER BY TTADATTINTFDETAIL.attcomponent
                </cfquery>
    
                <cfset scRetVar.QUERY.qAttIntfData=qAttIntfData>
    
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qAttIntfDataSum">
                    SELECT count(attend_id) attcomponent_value, emp_id, company_id, attend_code attcomponent FROM ttadattstatusdetail
                    WHERE (attend_date >= <cfqueryparam VALUE="#CreateODBCDate(arguments.startdatePeriod)#" CFSQLTYPE="cf_sql_timestamp"> AND attend_date <= <cfqueryparam VALUE="#CreateODBCDate(arguments.enddatePeriod)#" CFSQLTYPE="cf_sql_timestamp">)
                        AND company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                        AND emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    GROUP BY emp_id, company_id, attend_code
                </cfquery>
                <cfset scRetVar.QUERY.qAttIntfDataSum=qAttIntfDataSum>
    
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"PAYDATA")><!--- PAYDATA : TPYDEMPSALARYPARAM, TPYDEMPSALARYPARAM_HISTORY [table employee payroll data]--->
                <cfoutput>
                    <cfquery name="LOCAL.qPayData" datasource="#REQUEST.DSN.PAYROLL#">
                        SELECT TPYDEMPSALARYPARAM.currency_code, TPYDEMPSALARYPARAM.formula, TPYDEMPSALARYPARAM.effective_date,
                            #objFormula.SFD('TPYDEMPSALARYPARAM.salary','TPYDEMPSALARYPARAM.emp_id')# as salary,
                            TPYDEMPSALARYPARAM.taxlocation_code as TAXLOCATION, <!--- TCK2004-0559623 set alias for taxlocation_code---->
                            TPYDEMPSALARYPARAM.taxstatus, TPYDEMPSALARYPARAM.numdependent,TPYDEMPSALARYPARAM.payfrequency
                        FROM TPYDEMPSALARYPARAM
                        WHERE TPYDEMPSALARYPARAM.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                        AND TPYDEMPSALARYPARAM.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                    </cfquery>
                </cfoutput>
    
                <cfset scRetVar.QUERY.qPayData=qPayData>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"PAYFIELD")><!--- PAYFIELD : TPYDEMPPAYFIELD, TPYDEMPPAYFIELDHistory [table employee payroll field]--->
                <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qPayField">
                    SELECT TPYDEMPPAYFIELD.payfield_no, TPYDEMPPAYFIELD.effective_date payfield_date, TPYDEMPPAYFIELD.value payfield_value
                    FROM TPYDEMPPAYFIELD
                    WHERE TPYDEMPPAYFIELD.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                    AND TPYDEMPPAYFIELD.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    ORDER BY TPYDEMPPAYFIELD.payfield_no
                </cfquery>
                <cfset scRetVar.QUERY.qPayField=qPayField>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"PAYCOMP")><!--- PAYCOMP : TPYDEMPALLOWDEDUCT, TPYDEMPALLOWDEDUCTHISTORY [table employee allowance & deduction]--->
                <cfoutput>
                    <cfquery NAME="LOCAL.qPayComp" datasource="#REQUEST.DSN.PAYROLL#">
                        SELECT TPYDEMPALLOWDEDUCT.allowdeduct_code, TPYDEMPALLOWDEDUCT.allowdeduct_formula, TPYDEMPALLOWDEDUCT.effective_date,
                            #objFormula.SFD('TPYDEMPALLOWDEDUCT.allowdeduct_value','TPYDEMPALLOWDEDUCT.emp_id')# as allowdeduct_value,
                            TPYDEMPALLOWDEDUCT.formula_status, #objFormula.SFD('TPYDEMPALLOWDEDUCT.formula_result','TPYDEMPALLOWDEDUCT.emp_id')# as formula_result
                            ,end_date
                        FROM TPYDEMPALLOWDEDUCT
                        WHERE TPYDEMPALLOWDEDUCT.EMP_ID = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                        AND TPYDEMPALLOWDEDUCT.company_id = <cfqueryparam cfsqltype="CF_SQL_integer" value="#arguments.companyid#">
                        AND TPYDEMPALLOWDEDUCT.period_code = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                    </cfquery>
                </cfoutput>
    
                <cfset scRetVar.QUERY.qPayComp=qPayComp>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"RMINTFDATA")> <!--- RMINTFDATA : TRMDREIMINTF [table reimbursement interface process]--->
                 <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qReimInterface">
                    SELECT total, currency_code, reim_code, emp_id, period_code, paystartdate
                    FROM TRMDREIMINTF
                    WHERE emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    AND period_code = <cfqueryparam VALUE="#arguments.periodcode#" CFSQLTYPE="CF_SQL_VARCHAR">
                    AND company_code =  <cfqueryparam VALUE="#company_code#" CFSQLTYPE="CF_SQL_VARCHAR">
                    AND paystartdate =  <cfqueryparam VALUE="#CreateODBCDate(arguments.paydate)#" CFSQLTYPE="cf_sql_timestamp">
                </cfquery>
    
                <cfset scRetVar.QUERY.qReimInterface=qReimInterface>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"LNDATA")> <!--- LNDATA : TLNDLOANMASTER,TLNDLOANPROCESS [table loan master & loan process]--->
                 <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLoanData" ><!--- BUG51214-32277 --->
                    SELECT loan_code FROM TLNMLOANTYPE
                       WHERE company_code = <cfqueryparam VALUE="#company_code#" CFSQLTYPE="CF_SQL_VARCHAR">
                </cfquery>
    
                <cfset scRetVar.QUERY.qLoanData=qLoanData>
            </cfif>
            <cfif ListFindNoCase(lstreswordcategory,"LEAVEGRADEENT")> <!--- LEAVEGRADEENT : TTARLEAVEENTGRADE [table Leave Entitlement Grade]--->
                 <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qcountLeaveGrade">
                      select count(leavegrade_code) as cntdata
                    from TTADEMPLEAVEGRADE
                    WHERE emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    AND company_code =  <cfqueryparam VALUE="#company_code#" CFSQLTYPE="CF_SQL_VARCHAR">
                 </cfquery>
                 <cfquery datasource="#REQUEST.SDSN#" name="LOCAL.qLeaveGrade" maxrows="1">
                    SELECT leavegrade_code
                    FROM TTADEMPLEAVEGRADE
                    WHERE emp_id = <cfqueryparam VALUE="#arguments.empid#" CFSQLTYPE="CF_SQL_VARCHAR">
                    <cfif qcountLeaveGrade.cntdata GT 1>
                        AND effective_date < <cfqueryparam VALUE="#CreateODBCDate(arguments.paydate)#" CFSQLTYPE="cf_sql_timestamp">
                    <cfelse>
                        AND effective_date <= <cfqueryparam VALUE="#CreateODBCDate(arguments.paydate)#" CFSQLTYPE="cf_sql_timestamp">
                    </cfif>
                    AND company_code =  <cfqueryparam VALUE="#company_code#" CFSQLTYPE="CF_SQL_VARCHAR">
                    ORDER BY effective_date DESC
                </cfquery>
                
                <cfset scRetVar.QUERY.qLeaveGrade=qLeaveGrade>
            </cfif>
            <!---cfif listFindNoCase(lstreswordcategory, "ATTENDHOLIDAY")>
                <cfquery name="LOCAL.qCekHoliday" datasource="#REQUEST.SDSN#">
                    SELECT  start_date, end_date, lstreligion,lstnationality, lstworklocation,lstjobstatus, holiday_type
                    FROM TGEMHOLIDAY
                    WHERE ((Start_Date <= <cfqueryparam value="#createODBCDate(arguments.paydate)#" CFSQLType="CF_SQL_TIMESTAMP">
                    AND End_Date >= <cfqueryparam value="#createODBCDate(arguments.paydate)#" CFSQLType="CF_SQL_TIMESTAMP">)
                    OR (    
                            is_recur = 1
                        AND ((
                            (
                                (   (DAY(Start_Date) <= <cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND DAY(End_Date) <=<cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND MONTH(Start_Date) =<cfqueryparam value="#Month(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">) 
                                    OR 
                                    (DAY(Start_Date) >= <cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND DAY(End_Date) >=<cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND MONTH(End_Date) =<cfqueryparam value="#Month(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">))
                                AND DAY(Start_Date) > DAY(End_Date) AND MONTH(Start_Date) > MONTH(End_Date) 
                                AND YEAR(Start_Date) < YEAR(End_Date)
                            ) OR (
                                (   (DAY(Start_Date) <= <cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND DAY(End_Date) <=<cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND MONTH(Start_Date) =<cfqueryparam value="#Month(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">) 
                                    OR 
                                    (DAY(Start_Date) >= <cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND DAY(End_Date) >=<cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer"> AND MONTH(End_Date) =<cfqueryparam value="#Month(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">))
                                AND DAY(Start_Date) > DAY(End_Date) 
                                AND MONTH(Start_Date) < MONTH(End_Date) 
                                AND YEAR(Start_Date) = YEAR(End_Date)
                                )
                            )
                            OR
                            (
                                DAY(Start_Date) <= <cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">
                                AND 
                                MONTH(Start_Date) <= <cfqueryparam value="#Month(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">
                                AND 
                                DAY(End_Date) >= <cfqueryparam value="#DAY(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">
                                AND 
                                MONTH(End_Date) >= <cfqueryparam value="#Month(createODBCDate(arguments.paydate))#" CFSQLType="cf_sql_integer">
                            ))
                    ))
                    AND (Company_ID = 0 OR Company_ID = <cfqueryparam value="#arguments.companyid#" CFSQLType="cf_sql_integer">)
                </cfquery>      
                
                <cfif qCekHoliday.recordcount>
                    <cfloop query="qCekHoliday">
                        <cfset isholidays = 1>
                        <cfif Len(Trim(lstreligion)) or len(trim(lstnationality)) or Len(Trim(lstworklocation)) or Len(Trim(lstjobstatus))>
                            <cfif Len(Trim(lstreligion)) or len(trim(lstnationality))>
                                <cfquery name="LOCAL.qCekHoliday" datasource="#REQUEST.SDSN#">
                                    SELECT religion_code, '#qCekHoliday.holiday_type#' holiday_type, nationality_code FROM TEODEMPPERSONAL 
                                    WHERE emp_id = <cfqueryparam value="#arguments.empid#" CFSQLType="CF_SQL_VARCHAR">
                                    <cfif Len(Trim(lstreligion)) AND Len(Trim(lstnationality))>
                                        AND (
                                            religion_code IN (<cfqueryparam value="#lstreligion#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                            AND 
                                            nationality_code IN (<cfqueryparam value="#lstnationality#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                            )
                                    <cfelseif Len(Trim(lstreligion)) neq 0>
                                        AND religion_code IN (<cfqueryparam value="#lstreligion#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                    <cfelseif Len(Trim(lstnationality))>
                                        AND nationality_code IN (<cfqueryparam value="#lstnationality#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                    </cfif> 
                                </cfquery>
                                <cfif qCekHoliday.recordcount eq 0>
                                    <cfset isholidays = 0>
                                </cfif>
                            <cfelse>
                                <cfset isholidays = 0>
                            </cfif>
                            <cfif isholidays eq 0>
                                <cfif Len(Trim(lstworklocation)) or Len(Trim(lstjobstatus))>
                                    <cfquery name="LOCAL.qCekHoliday" datasource="#REQUEST.SDSN#">
                                        SELECT work_location_code,job_status_code, '#qCekHoliday.holiday_type#' holiday_type 
                                        FROM TEODEMPCOMPANY 
                                        WHERE emp_id = <cfqueryparam value="#arguments.empid#" CFSQLType="CF_SQL_VARCHAR">
                                        <cfif Len(Trim(lstworklocation)) AND Len(Trim(lstjobstatus))>
                                            AND (
                                                work_location_code IN (<cfqueryparam value="#lstworklocation#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                                AND
                                                job_status_code IN (<cfqueryparam value="#lstjobstatus#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                                )
                                        <cfelseif Len(Trim(lstworklocation)) neq 0>
                                            AND work_location_code IN (<cfqueryparam value="#lstworklocation#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                        <cfelseif Len(Trim(lstjobstatus))>
                                            AND job_status_code IN (<cfqueryparam value="#lstjobstatus#" CFSQLType="CF_SQL_VARCHAR" list="yes">)
                                        </cfif>                             
                                    </cfquery>
                                </cfif> 
                            </cfif>
                        </cfif>
                    </cfloop>       
                </cfif>
                <cfset scRetVar.QUERY.qCekHoliday = qCekHoliday>
            </cfif--->
        
            <cfreturn scRetVar>
        </cffunction>
        <!---End Custom get Value Formula TCK2102-0626536 alv  ------------------------------------------------------------------------------------------------------------- --->
		
		<!---
		<cffunction name="SendEmail">
		    <cfreturn true>
		</cffunction>
		--->
		
        <cffunction name="GetApproverListGD">
            <cfset flgUnfinal = 0>
            <cfset lstBtnToShow = "0">
            <cfset reqno = FORM.reqno>
            <cfset empid = FORM.empid>
            <cfset formno = FORM.formno>
            <cfset periodcode = FORM.periodcode>
            <cfset flgUnfinal = 0>
            <cfset local.strckListApprover = GetApproverList(reqno=FORM.reqno,empid=FORM.empid,reqorder=FORM.reqorder,varcoid=REQUEST.SCOOKIE.COID,varcocode=REQUEST.SCOOKIE.COCODE)>
            <cfset retVarCheckParam = isGeneratePrereviewer()>
            <cfquery name="qCheckHPerReviewer" datasource="#REQUEST.SDSN#" >
            	SELECT head_status from TPMDPERFORMANCE_EVALH
            	where reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
            	AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
            	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
            	AND reviewer_empid = <cfqueryparam value="#REQUEST.SCOOKIE.USER.EMPID#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfquery name="qCheckSelf" datasource="#REQUEST.SDSN#" >
            	SELECT form_no,head_status from TPMDPERFORMANCE_EVALH
            	where reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
            	AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
            	AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
            	AND reviewer_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
            	and form_no = <cfqueryparam value="#formno#" cfsqltype="cf_sql_varchar">
            	and request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfquery name="qCheckIfRequestIsUnfinal" datasource="#request.sdsn#">
            	SELECT <cfif request.dbdriver eq "MSSQL"> top 1    </cfif> modified_by, reviewer_empid
            	FROM TPMDPERFORMANCE_EVALH 
            	WHERE request_no = <cfqueryparam value="#reqno#" cfsqltype="cf_sql_varchar">
            	ORDER BY review_step DESC
            	<cfif request.dbdriver eq "MYSQL"> limit 1</cfif>   
            </cfquery>
            <cfif ListFindNoCase(qCheckIfRequestIsUnfinal.modified_by,"unfinal","|") gt 0 AND qCheckIfRequestIsUnfinal.reviewer_empid neq REQUEST.SCOOKIE.USER.EMPID>
            	<cfset flgUnfinal = 1>
            </cfif>
            
            <cfif len(reqno)>
                <cfif retVarCheckParam eq true>
                    <cfif (ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lastapprover) gt ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lstapprover)) AND (strckListApprover.lastapprover neq strckListApprover.lstapprover) AND qCheckHPerReviewer.head_status eq 0 AND NOT ListFindNoCase(strckListApprover.CURRENT_OUTSTANDING_LIST,request.scookie.user.uid) >
                      <cfset SFLANG=Application.SFParser.TransMLang("JSApprover in higher step has approved this performance form, you draft can't be proceed",true)>
                      
                    <cfelse>
                      <cfswitch expression="#StrckListApprover.status#"> 
                        <cfcase value="0">
                          <cfif StrckListApprover.approver_headstatus eq 1>
                            <cfset lstBtnToShow = "0">
                          <cfelseif StrckListApprover.approver_headstatus eq 0>
                            <cfset lstBtnToShow = "0,1,3,4,6">
                          <cfelseif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                            <cfset lstBtnToShow = "0,1,3,4,6">
                          <cfelse>
                            <cfset lstBtnToShow = "0,1,3,4,6">
                          </cfif>
                        </cfcase>
                        <cfcase value="1">
                          <cfif qCheckSelf.recordcount eq 0 >
                            <cfif qCheckHPerReviewer.recordcount gt 0>
                              <cfif qCheckHPerReviewer.head_status eq '0'>
                                <cfset lstBtnToShow = "0,1,3,4,6">
                              </cfif>
                            <cfelse>
                              <cfset lstBtnToShow = "0,3,4,6">
                            </cfif>
                          <cfelse>
                            <cfif qCheckHPerReviewer.recordcount gt 0>
                              <cfif qCheckHPerReviewer.head_status eq '0' AND qCheckSelf.head_status eq 1>
                                <cfset lstBtnToShow = "0,1,2,3,4,6">
                              <cfelse>
                                <cfif qCheckHPerReviewer.head_status neq 1>
                                  <cfset lstBtnToShow = "0,1,3,4,6">
                                <cfelse>
                                  <cfset lstBtnToShow = "0">
                                </cfif>
                              </cfif>
                            <cfelse>
                              <cfif strckListApprover.lastapprover eq "">
                                <cfset lstBtnToShow = "0,3,4,6">
                              <cfelse>
                                <cfset lstBtnToShow = "0,2,3,4,6">
                              </cfif>
                              
                            </cfif>
                          </cfif>
                          <cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                          
                          <cfelse>
                            
                          </cfif>
                        </cfcase>
                        <cfcase value="2">
                          <cfset yesIsApprover = 0>
                          <cfloop list="#StrckListApprover.FullListApprover#" delimiters="," index="idxLoop">
                            <cfif Listfindnocase(idxLoop,request.scookie.user.empid,"|") gt 0>
                              <cfset yesIsApprover = 1>
                            <cfelseif idxLoop eq request.scookie.user.empid>
                              <cfset yesIsApprover = 1>
                            </cfif>
                          </cfloop>
                          <cfif StrckListApprover.approver_headstatus eq 1 or (not listfindnocase(StrckListApprover.LstApprover,request.scookie.user.empid) AND yesIsApprover eq 0)>
                            <cfset lstBtnToShow = "0">
                          <cfelse>
                            <cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                              <cfset lstBtnToShow = "0,3,4,6">
                            <cfelse>
                              <cfset lstBtnToShow = "0,3,4,6">
                            </cfif>
                            <cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                                <cfset lstBtnToShow = "0,2,3,4,6">
                            </cfif>
                          </cfif>
                          <cfif flgUnfinal eq 1>
                            <cfset lstBtnToShow = "0">
                          <cfelseif ListFindNoCase(qCheckIfRequestIsUnfinal.modified_by,"unfinal","|") gt 0 AND qCheckIfRequestIsUnfinal.reviewer_empid eq REQUEST.SCOOKIE.USER.EMPID>
                              <cfset lstBtnToShow =  "0,3,4,6"/> 
                            <cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                              <cfset lstBtnToShow =ListAppend(lstBtnToShow, '2' ) >
                            </cfif>
                          </cfif>
                        </cfcase>
                        <cfcase value="3">
                          <cfif StrckListApprover.lastapprover eq REQUEST.SCOOKIE.USER.EMPID>
                            <cfset lstBtnToShow = "0,5,6">
                          </cfif>
                        </cfcase>
                        <cfcase value="4">
                          <cfset newlistrevise = StrckListApprover.REVISE_LIST_APPROVER>
                          <cfset delmulaidari = ListFindNoCase(StrckListApprover.REVISE_LIST_APPROVER,StrckListApprover.LASTAPPROVER,",")>
                          <cfif delmulaidari gt 0 AND val(delmulaidari-1) gt 1 >
                            <cfset tempDelTo = val(listlen(StrckListApprover.REVISE_LIST_APPROVER) - delmulaidari)> 
                            <cfloop from="#delmulaidari#" to="#val(delmulaidari+tempDelTo)#" index="idxdel">
                              <cfset newlistrevise = ListDeleteAt(newlistrevise, "#idxdel#",",")>
                            </cfloop>
                          <cfelse>
                            <cfset newlistrevise = ListDeleteAt(newlistrevise, "#delmulaidari#",",")>
                          </cfif>
                          <cfif ListLen(ListLast(newlistrevise,','),'|') eq 1>
                            <cfif REQUEST.SCOOKIE.USER.EMPID eq ListLast(newlistrevise)>
                                <cfif REQUEST.SCOOKIE.USER.EMPID neq empid>
                                  <cfif qCheckSelf.recordcount gt 0>
                                    <cfset lstBtnToShow = "0,2,3,4,6">
                                  <cfelse>
                                    <cfset lstBtnToShow = "0,3,4,6">
                                  </cfif>
                                <cfelse>
                                  <cfset lstBtnToShow = "0,3,4,6">
                                </cfif>
                            </cfif>
                          <cfelse>
                            <cfloop list="#ListLast(newlistrevise,',')#" delimiters="|" index="idxRevise">
                              <cfif REQUEST.SCOOKIE.USER.EMPID eq idxRevise>
                                <cfif idxRevise neq empid>
                                  <cfif qCheckSelf.recordcount gt 0>
                                    <cfset lstBtnToShow = "0,2,3,4,6">
                                  <cfelse>
                                    <cfset lstBtnToShow = "0,3,4,6">
                                  </cfif>
                                <cfelse>
                                  <cfset lstBtnToShow = "0,3,4,6">
                                </cfif>
                              </cfif>
                            </cfloop>
                          </cfif>
                        </cfcase>
                        <cfcase value="9">
                            <cfquery name="qCheckLastApprover" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
                            SELECT	<cfif request.dbdriver eq "MSSQL"> TOP 1</cfif>  reviewer_empid
                            FROM	tpmdperformance_evalh
                            WHERE	reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                            AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
                            AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                            order by review_step desc
                            <cfif request.dbdriver eq "MYSQL"> limit 1</cfif> 
                            </cfquery>
                          
                          <cfif request.scookie.user.empid eq qCheckLastApprover.reviewer_empid>
                            <cfset lstBtnToShow = "0,5,6">
                          <cfelse>
                            <cfset lstBtnToShow = "0">
                          </cfif>
                        </cfcase>
                        <cfdefaultcase>
                          <cfset lstBtnToShow = "0">
                        </cfdefaultcase> 
                      </cfswitch>
                    </cfif>
                <cfelse>
                    <cfif (ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lastapprover) gt ListFindNoCase(strckListApprover.FULLLISTAPPROVER,strckListApprover.lstapprover)) AND (strckListApprover.lastapprover neq strckListApprover.lstapprover) AND qCheckHPerReviewer.head_status eq 0 AND NOT ListFindNoCase(strckListApprover.CURRENT_OUTSTANDING_LIST,request.scookie.user.uid) >
                        <cfset SFLANG=Application.SFParser.TransMLang("JSApprover in higher step has approved this performance form, you draft can't be proceed",true)>
                    <cfelse>
                      <cfswitch expression="#strckListApprover.status#"> 
                        <cfcase value="0">
                            <cfif strckListApprover.approver_headstatus eq 1>
                              <cfset lstBtnToShow = "0">
                            <cfelseif strckListApprover.approver_headstatus eq 0>
                              <cfset lstBtnToShow = "0,1,3,4,6">
                            <cfelseif listfindnocase(listlast(strckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                              <cfset lstBtnToShow = "0,1,3,4,6">
                            <cfelse>
                              <cfset lstBtnToShow = "0,1,3,4,6">
                            </cfif>
                        </cfcase>
                        <cfcase value="1"><!--- udah bisa revise, tapi head_status belum berubah --->
                            <cfif strckListApprover.lastapprover eq request.scookie.user.empid AND StrckListApprover.APPROVER_HEADSTATUS EQ 1>
                              <cfset lstBtnToShow = "0">
                            <cfelseif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                              <cfset lstBtnToShow = "0,2,3,4,6">
                            <cfelseif StrckListApprover.approver_headstatus eq 0>
                              <cfset lstBtnToShow = "0,2,3,4,6">
                            <cfelse>
                                <cfset lstBtnToShow = "0,2,3,4,6">
                            </cfif>
                        </cfcase>
                        <cfcase value="2">
                            <cfset yesIsApprover = 0>
                            <cfloop list="#StrckListApprover.FullListApprover#" delimiters="," index="idxLoop">
                              <cfif Listfindnocase(idxLoop,request.scookie.user.empid,"|") gt 0>
                                <cfset yesIsApprover = 1>
                              <cfelseif idxLoop eq request.scookie.user.empid>
                                <cfset yesIsApprover = 1>
                              </cfif>
                            </cfloop>
                            <cfif StrckListApprover.approver_headstatus eq 1 or (not listfindnocase(StrckListApprover.LstApprover,request.scookie.user.empid) AND yesIsApprover eq 0)>
                              <cfset lstBtnToShow = "0">
                            <cfelse>
                              <cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                                <cfset lstBtnToShow = "0,3,4,6">
                              <cfelse>	
                                <cfset lstBtnToShow = "0,3,4,6">
                              </cfif>
                              
                              <cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                                <cfset lstBtnToShow =ListAppend(lstBtnToShow, '2' ) >
                              </cfif>
                            </cfif>
                            <cfif flgUnfinal eq 1>
                              <cfset lstBtnToShow = "0">
                            <cfelseif ListFindNoCase(qCheckIfRequestIsUnfinal.modified_by,"unfinal","|") gt 0 AND qCheckIfRequestIsUnfinal.reviewer_empid eq REQUEST.SCOOKIE.USER.EMPID>
                                <cfset lstBtnToShow =  "0,3,4,6"/> 
                              <cfif StrckListApprover.approverbefore_headstatus and not listfindnocase(listfirst(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                                <cfset lstBtnToShow =ListAppend(lstBtnToShow, '2' ) >
                              </cfif>
                            </cfif>
                        </cfcase>
                        <cfcase value="3">
                            <cfif listfindnocase(listlast(StrckListApprover.FullListApprover),request.scookie.user.empid,"|")>
                            <cfset lstBtnToShow = "0,5,6">
                            <cfelse>
                            <cfset lstBtnToShow = "0">
                            </cfif>
                        </cfcase>
                        <cfcase value="4">
                              <cfset newlistrevise = StrckListApprover.REVISE_LIST_APPROVER>
                              <cfset delmulaidari = ListFindNoCase(StrckListApprover.REVISE_LIST_APPROVER,StrckListApprover.LASTAPPROVER,",")>
                              <cfif delmulaidari gt 0 AND val(delmulaidari-1) gt 1 >
                                <cfset tempDelTo = val(listlen(StrckListApprover.REVISE_LIST_APPROVER) - delmulaidari)>
                                <cfloop from="#delmulaidari#" to="#val(delmulaidari+tempDelTo)#" index="idxdel">
                                  <cfset newlistrevise = ListDeleteAt(newlistrevise, "#idxdel#",",")>
                                </cfloop>
                              <cfelse>
                                <cfset newlistrevise = ListDeleteAt(newlistrevise, "#delmulaidari#",",")>
                              </cfif>
                              <cfif ListLen(ListLast(newlistrevise,','),'|') eq 1>
                                <cfif REQUEST.SCOOKIE.USER.EMPID eq ListLast(newlistrevise)>
                                    <cfif REQUEST.SCOOKIE.USER.EMPID neq empid>
                                      <cfif qCheckSelf.recordcount gt 0>
                                        <cfset lstBtnToShow = "0,2,3,4,6">
                                      <cfelse>
                                        <cfset lstBtnToShow = "0,3,4,6">
                                      </cfif>
                                      
                                    <cfelse>
                                      <cfset lstBtnToShow = "0,3,4,6">
                                    </cfif>
                                </cfif>
                              <cfelse>
                                <cfloop list="#ListLast(newlistrevise,',')#" delimiters="|" index="idxRevise">
                                  <cfif REQUEST.SCOOKIE.USER.EMPID eq idxRevise>
                                    <cfif idxRevise neq empid>
                                      <cfif qCheckSelf.recordcount gt 0>
                                        <cfset lstBtnToShow = "0,2,3,4,6">
                                      <cfelse>
                                        <<cfset lstBtnToShow = "0,3,4,6">
                                      </cfif>
                                      
                                    <cfelse>
                                      <cfset lstBtnToShow = "0,3,4,6">
                                    </cfif>
                                  </cfif>
                                </cfloop>
                              </cfif>
                        </cfcase>
                        <cfcase value="9">
                            <cfquery name="qCheckLastApprover" datasource="#REQUEST.SDSN#" debug="#REQUEST.ISDEBUG#">
                            SELECT	<cfif request.dbdriver eq "MSSQL"> TOP 1</cfif>  reviewer_empid
                            FROM	tpmdperformance_evalh
                            WHERE	reviewee_empid = <cfqueryparam value="#empid#" cfsqltype="cf_sql_varchar">
                            AND period_code = <cfqueryparam value="#periodcode#" cfsqltype="cf_sql_varchar">
                            AND company_code = <cfqueryparam value="#REQUEST.SCOOKIE.COCODE#" cfsqltype="cf_sql_varchar">
                            order by review_step desc
                            <cfif request.dbdriver eq "MYSQL"> limit 1</cfif> 
                            </cfquery>
                          
                          <cfif request.scookie.user.empid eq qCheckLastApprover.reviewer_empid>
                            <cfset lstBtnToShow = "0,5,6">
                          <cfelse>
                            <cfset lstBtnToShow = "0">
                          </cfif>
                        </cfcase>
                        <cfdefaultcase>
                          <cfset lstBtnToShow = "0">
                        </cfdefaultcase> 
                      </cfswitch>
                    
                    </cfif>
                </cfif>
            <cfelseif not len(periodcode)>
            	<cfset lstBtnToShow = "0">
            <cfelseif listlast(strckListApprover.FullListApprover) eq request.scookie.user.empid>
            	<cfset lstBtnToShow = "0,3,4,6">
            <cfelse>
               	<cfset lstBtnToShow = "0,3,4,6">
            </cfif>
            
            <cfset strckListApprover['lstBtnToShow'] = lstBtnToShow>
            <cfreturn strckListApprover>
        </cffunction>
       
    	<cffunction name="filterFormStatus">
    		<cfparam name="source" default="filter">
    		<cfparam name="search" default="">
    		<cfparam name="member" default="">
    		<cfparam name="phase" default="2"> <!--- 1: Plan, 2: Evaluation --->
    		<cfparam name="hdn_periodcode" default="">
    		
			<cfif structkeyexists(REQUEST,"SHOWCOLUMNGENERATEPERIOD")>
				<cfset local.ReturnVarCheckCompParam = REQUEST.SHOWCOLUMNGENERATEPERIOD>
			<cfelse>
				<cfset local.ReturnVarCheckCompParam = isGeneratePrereviewer()>
			</cfif>
    		
    		<cfset local.pcode = hdn_periodcode>
    
    		<cfset LOCAL.searchText=trim(search)>
    		<cfoutput>
    		    <cfquery name="local.qData" datasource="#request.sdsn#">
    		        SELECT DISTINCT RS.code as fscode, RS.name_#request.scookie.lang# as fsname
    	            FROM TGEMREQSTATUS RS
    	            WHERE 
    	                1=1
    					<cfif len(searchText)>
    						AND RS.name_#request.scookie.lang# LIKE <cfqueryparam value="%#searchText#%" cfsqltype="CF_SQL_VARCHAR">
    					</cfif>
    					<cfif len(member)>
    						AND RS.code NOT IN (<cfqueryparam value="#member#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
    					</cfif>
    					AND RS.code NOT IN ('5','8') <!---Exclude cancel dan rejected--->
    					<cfif ReturnVarCheckCompParam >
    					    AND RS.code NOT IN ('0') <!---Exclude Draft--->
    					</cfif>
    		    </cfquery>
    		</cfoutput> 
    		<cfset LOCAL.vResult="">
    		<cfloop query="qData"><cfset vResult=vResult & "
    			arrEntryList[#currentrow-1#]=""#JSStringFormat(fscode & "=" & fsname )#"";">
    	    </cfloop>
    		<cfoutput>
    	    	<script>
    			arrEntryList=new Array();
    	    		<cfif len(vResult)>
    				#vResult#
    	    		</cfif>
    			</script>
    		</cfoutput>
    	</cffunction>
    	
    	

	<cffunction name="DeleteAllPerfEvalByFormNo">
		<cfparam name="form_no" default="">
		<cfparam name="company_id" default="#REQUEST.Scookie.COID#">
		<cfparam name="company_code" default="#REQUEST.Scookie.COCODE#">
		<cftry>	
			<cfquery name="LOCAL.qGetPerfEvalH" datasource="#REQUEST.SDSN#">
				SELECT request_no,reviewee_posid,reviewee_empid,period_code FROM TPMDPERFORMANCE_EVALH WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
				AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
				order by created_date desc
			</cfquery>
			
			<cfquery name="LOCAL.qGetAdjustD" datasource="#REQUEST.SDSN#">
				select adjust_no,form_no from TPMDPERFORMANCE_ADJUSTD  WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>
            <cfset otherAdjustDNo = qGetAdjustD.adjust_no>
            <cfif qGetAdjustD.recordcount gt 0>
			    <cfquery name="LOCAL.deleteAdjustD" datasource="#REQUEST.SDSN#" result="adjustD">
			        delete from TPMDPERFORMANCE_ADJUSTD WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
				    AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
		    	</cfquery>
            </cfif>
			
		    <cfif qGetPerfEvalH.recordcount eq 0 > 
    			<cfquery name="LOCAL.qGetPerfEvalH" datasource="#REQUEST.SDSN#">
    				SELECT distinct req_no request_no,reviewee_posid,reviewee_empid,period_code FROM TPMDPERFORMANCE_EVALGEN WHERE form_no =  <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    				AND company_id = <cfqueryparam value="#REQUEST.Scookie.COID#" cfsqltype="CF_SQL_VARCHAR">
    				<!--- and req_no = <cfqueryparam value="#qGetPerfEvalH.request_no#" cfsqltype="CF_SQL_VARCHAR">  --->
    			</cfquery>
    		</cfif>
			
			<cfloop query="qGetPerfEvalH">
    			<cfquery name="LOCAL.qDelPerfPlanREQUEST" datasource="#REQUEST.SDSN#">
    				DELETE FROM TCLTREQUEST WHERE req_no = <cfqueryparam value="#qGetPerfEvalH.request_no#" cfsqltype="CF_SQL_VARCHAR"> 
    				AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    				AND UPPER(req_type) = 'PERFORMANCE.EVALUATION'
    			</cfquery>
    			
    			<cfquery name="LOCAL.qDelPerfEvalGENERATE" datasource="#REQUEST.SDSN#">
    				DELETE FROM TPMDPERFORMANCE_EVALGEN WHERE req_no = <cfqueryparam value="#qGetPerfEvalH.request_no#" cfsqltype="CF_SQL_VARCHAR"> 
    				AND form_no =  <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR">  AND company_id = <cfqueryparam value="#REQUEST.Scookie.COID#" cfsqltype="CF_SQL_VARCHAR">
    			</cfquery>
    			
	            <cfquery name="local.qGetOrgUnit" datasource="#request.sdsn#">
	                SELECT dept_id FROM TEOMPOSITION WHERE position_id = <cfqueryparam value="#qGetPerfEvalH.reviewee_posid#" cfsqltype="cf_sql_integer"> 
	                AND company_id = <cfqueryparam value="#REQUEST.Scookie.COID#" cfsqltype="CF_SQL_VARCHAR"> GROUP BY dept_id
	            </cfquery>
	            <cfquery name="local.qGetLibraryDetails" datasource="#request.sdsn#">
	                SELECT orgunit_id FROM TPMDPERFORMANCE_EVALKPI WHERE orgunit_id = <cfqueryparam value="#qGetOrgUnit.dept_id#" cfsqltype="cf_sql_integer">
	                    AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#qGetPerfEvalH.period_code#" cfsqltype="cf_sql_varchar">
	            </cfquery>
	            <cfif qGetLibraryDetails.recordcount neq 0>
    				<cfquery name="Local.qPMDel1" datasource="#request.sdsn#">	
    					DELETE FROM TPMDPERFORMANCE_EVALKPI WHERE  orgunit_id = <cfqueryparam value="#qGetOrgUnit.dept_id#" cfsqltype="cf_sql_integer">
	                    AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="cf_sql_varchar">
	                    AND period_code = <cfqueryparam value="#qGetPerfEvalH.period_code#" cfsqltype="cf_sql_varchar">
    				</cfquery>
	            </cfif>
			</cfloop>
			
    		<cfquery name="LOCAL.qDelPerfEvalNote" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_EVALNOTE WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		</cfquery>
    		
    		<cfquery name="LOCAL.qDelPerfEvalD" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_EVALD WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		</cfquery>
	
    		<cfquery name="LOCAL.qDelPerfEvalH" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_EVALH WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    				AND request_no = <cfqueryparam value="#qGetPerfEvalH.request_no#" cfsqltype="CF_SQL_VARCHAR"> 
    		</cfquery>
    		
    		<cfquery name="LOCAL.qDelPerfFINAL" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDPERFORMANCE_FINAL WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    			AND company_code = <cfqueryparam value="#REQUEST.Scookie.COCODE#" cfsqltype="CF_SQL_VARCHAR">
    		</cfquery>
    		<cfquery name="LOCAL.qDelPerfAttCompPoint" datasource="#REQUEST.SDSN#">
    			DELETE FROM TPMDEVALD_COMPPOINT WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="CF_SQL_VARCHAR"> 
    		</cfquery>
            <cfquery name="LOCAL.qGetExistingEvalTech" datasource="#request.sdsn#">
                SELECT form_no, file_attachment FROM TPMDPERF_EVALATTACHMENT WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar"> 
                    AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <cfloop query="qGetExistingEvalTech">
                <CF_SFUPLOAD ACTION="DELETE" CODE="evalattachment" FILENAME="#qGetExistingEvalTech.file_attachment#" output="xlsuploadedDelete">
            </cfloop>

            <cfquery name="LOCAL.qDeleteAttachment" datasource="#request.sdsn#">
                DELETE FROM TPMDPERF_EVALATTACHMENT  WHERE form_no = <cfqueryparam value="#form_no#" cfsqltype="cf_sql_varchar"> 
                    AND company_id = <cfqueryparam value="#request.scookie.coid#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <!---Delete data 360--->
            <cfif qGetPerfEvalH.recordcount NEQ 0>
                <cfquery name="LOCAL.qGetAllRater" datasource="#request.sdsn#">
                    SELECT ratercode,period_code,rater_empid,reviewee_empid FROM TPMD360RATER WHERE period_code = <cfqueryparam value="#qGetPerfEvalH.period_code#" cfsqltype="cf_sql_varchar"> 
                        AND reviewee_empid = <cfqueryparam value="#qGetPerfEvalH.reviewee_empid#" cfsqltype="cf_sql_varchar">
                </cfquery>
                <cfloop query="qGetAllRater">
                    <cfquery name="LOCAL.qDeleteRaterAnswer" datasource="#request.sdsn#">
                        DELETE FROM TPMD360ANSWER  WHERE ratercode = <cfqueryparam value="#qGetAllRater.ratercode#" cfsqltype="cf_sql_varchar"> 
                    </cfquery>
                </cfloop>
                <cfquery name="LOCAL.qUpdateStatusRater" datasource="#request.sdsn#">
                    UPDATE TPMD360RATER SET status = 'NEW', total_score = NULL
                    WHERE period_code = <cfqueryparam value="#qGetPerfEvalH.period_code#" cfsqltype="cf_sql_varchar"> 
                        AND reviewee_empid = <cfqueryparam value="#qGetPerfEvalH.reviewee_empid#" cfsqltype="cf_sql_varchar">
                </cfquery>
            </cfif>
            <!---Delete data 360--->
    		
			<cfset LOCAL.retVarReturn=true>
			<cfcatch>
			    <cfset LOCAL.retVarReturn=false>
			</cfcatch>
        </cftry>
        
        <cfreturn retVarReturn>
	    
	</cffunction>
      
	 <cffunction name="ListingAttendanceHistory">
		<cfset LOCAL.scParam=paramRequest()>
		<cfquery name="local.qGetAttCodeList" datasource="#request.sdsn#">
			SELECT lst_code FROM TPMDCOMPPOINT
			WHERE period_code = <cfqueryparam value="#URL.periodcode#" cfsqltype="cf_sql_varchar">
			AND show_history = 'Y' 
			
		</cfquery>
		<cfset local.lstAttCode = ''>
		<cfloop query="qGetAttCodeList">
		
			<cfset local.lstAttCode = ListAppend(lstAttCode,ReplaceNoCase(qGetAttCodeList.lst_code,"'","","all"))>
		</cfloop>
		<cfset local.lstAttCode = lstAttCode EQ '' ? '-' : lstAttCode >
		<cfset lstAttCode = ListQualify(lstAttCode,"'")>
		<cfset LOCAL.lsField="attend_id, emp_id, b.attend_code, attend_date:date, attend_name_#REQUEST.SCOOKIE.LANG# attend_name">     
		<cfset LOCAL.lsTable="TTAMATTSTATUS a:=TTADATTSTATUSDETAIL b(b.attend_code = a.attend_code)">
		<cfset LOCAL.dataQuery=Application.SFSec.DAuthSQL("0,1,2,3","hrm.employee","emp_id")>
		<cfset LOCAL.AuthData="EMPLOYEE">
		<cfset LOCAL.lsFilter=" b.emp_id='#URL.empid#' ">
		<cfset LOCAL.lsFilter= lsFilter & " AND attend_date >= (select period_startdate from tpmmperiod	WHERE period_code = '#URL.periodcode#' and company_code  = '#REQUEST.SCOOKIE.COCODE#' ) AND attend_date <= ( select period_enddate from tpmmperiod WHERE period_code = '#URL.periodcode#' and company_code  = '#REQUEST.SCOOKIE.COCODE#' ) AND b.attend_code IN ( #lstAttCode# ) AND b.attend_code = '#URL.ATTEND_CODE#'">
		<cfset ListingData(scParam,{fsort="attend_date",dataQuery=dataQuery,AuthData=AuthData,lsField=lsField,lsFilter=lsFilter,lsTable=lsTable,pid="attend_id"})>
	</cffunction>
	
	
    <cffunction name="SendEmail" access="public" returntype="boolean" hint="handles requests notification">
    	<cfreturn true>
    </cffunction>

</cfcomponent>






