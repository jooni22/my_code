xquery=
xquery version "1.0-ml";
declare namespace sc = "http://example.com/study-configuration";
declare namespace envelope = "http://marklogic.com/entity-services";

import module namespace invoke-helper = "http://example.com/data-capture-hub/common/invoke-helper" at "/common/invoke-helper.xqy";

declare function local:checkPRO1($study, $ds) {
  let $ref := invoke-helper:execute-function-specified-database(
      function() { 
        cts:search(/envelope:envelope/envelope:instance/mdmsReferenceData, cts:and-query((
          cts:element-value-query(xs:QName("STUDY_CD"), $study),
          cts:collection-query("latest")
        )))[1]
      },
      'XYZ-REFERENCE-LIVE', 'query'
  )
  let $pd := $ref/ACCOUNT_PARTY_DESC/fn:string()
  let $is-usa := $ref/LEAD_AFFILIATE_CTY_DESC/fn:string() eq "United States"
  let $updatedDS := if ($pd eq 'PRO1' and $is-usa) 
             then "USMA" 
             else if($pd eq 'PRO1' and fn:not($is-usa))
             then "PRO1"
             else ()
             
  return if($updatedDS) then $updatedDS else $ds
};

declare function local:checkINHEnabled($studyNr, $ds) {
  let $studies := fn:doc(cts:uri-match("/XYZcore/studyconfig/*/studyconfig.xml"))/sc:studyconfiguration/sc:studies[./@datasourceShortName eq $ds and ./@StudyEnvironment eq 'prod']
  let $study := $studies/sc:study[./sc:status/xs:string(.) eq 'Active' and ./@enabled/xs:string(.) eq 'true' and ./@StudyNumber/xs:string(.) eq $studyNr]
  return if($study) then fn:true() else fn:false()
};



let $response := json:object()
let $env := "prod"
let $dsList := invoke-helper:execute-function-specified-database(
      function() { 
        for $doc in cts:uri-match("/XYZcore/studyconfig/*/studyconfig.xml")
        let $ds := fn:doc($doc)/sc:studyconfiguration/sc:studies[./@StudyEnvironment eq $env]/@datasourceShortName
        return $ds
      },
      'XYZ-FINAL-LIVE', 'query'
  )

(: create dateTime property :)
let $_ := map:put($response, "requestTime", fn:current-dateTime())

(: create the ingested studies count from Wave object :)
let $ingested := json:object()
let $_ := map:put($ingested, "total", 0)
let $_ := (
  for $ds in $dsList
  let $count := invoke-helper:execute-function-specified-database(
      function() { 
        let $_ := (
          if(fn:contains($ds,"PRO1"))
          then (
            let $_ := (map:put($ingested, "PRO1_usma", 0), map:put($ingested, "PRO1_PRO1", 0))
            let $_ := (
              let $studies := (
                for $doc in cts:uri-match("/XYZcore/studyconfig/*/studyconfig.xml")
                let $study := fn:doc($doc)/sc:studyconfiguration/sc:studies[./@datasourceShortName eq $ds and ./@StudyEnvironment eq $env]/sc:study[./sc:status/xs:string(.) eq 'Active' and ./@enabled/xs:string(.) eq 'true']/@StudyNumber
                return $study
              )
              for $s in $studies
              let $updatedDS := if(local:checkPRO1($s, $ds) eq "PRO1") then "PRO1_PRO1" else "PRO1_usma"
              let $_ := (
                map:put($ingested, $updatedDS, fn:sum((map:get($ingested, $updatedDS), 1))), 
                map:put($ingested, "total", fn:sum((map:get($ingested, "total"), 1)))
              )
              return ()
            )
            return ()
          )
          else (
            let $count := 
              fn:count(
                        for $doc in cts:uri-match("/XYZcore/studyconfig/*/studyconfig.xml")
                        let $study := fn:doc($doc)/sc:studyconfiguration/sc:studies[./@datasourceShortName eq $ds and ./@StudyEnvironment eq $env]/sc:study[./sc:status/xs:string(.) eq 'Active' and ./@enabled/xs:string(.) eq 'true']
                        return $study
                      )
            let $_ := (map:put($ingested, $ds, $count), map:put($ingested, "total", fn:sum((map:get($ingested, "total"), $count))))
            return ()
          )
        )
        return ()
      },
      'XYZ-FINAL-LIVE', 'query'
  )
  return $count
)
let $_ := map:put($response, "ingestedStudies", $ingested)

(: BER studies :) 
let $BERStudies := json:object()
let $_ := map:put($BERStudies, "total", 0)
let $_ := (map:put($BERStudies, "PRO1_usma", 0), map:put($BERStudies, "PRO1_PRO1", 0))
let $studyConfig := invoke-helper:execute-function-specified-database(
      function() { 
        fn:doc("/saegeneration/config/StudyConfig.json")
      },
      'BER-FINAL-LIVE', 'query'
  )

let $dsForStudyConfig := (
for $study in $studyConfig/Studies[./active eq "ON"]/study
let $dsForStudy := invoke-helper:execute-function-specified-database(
      function() { 
        (for $doc in cts:uri-match("/XYZcore/studyconfig/*/studyconfig.xml")
        let $ds := fn:doc($doc)/sc:studyconfiguration/sc:studies[./sc:study/@StudyNumber eq $study]/@datasourceShortName
        return $ds)[1]
      },
      'XYZ-FINAL-LIVE', 'query'
  )
let $_ := (
  let $updatedDS := (
    if(local:checkPRO1($study, $dsForStudy) eq "PRO1") 
    then "PRO1_PRO1" 
    else if(local:checkPRO1($study, $dsForStudy) eq "USMA")
    then "PRO1_usma"
    else ()
  )
  let $_ := (
    if($updatedDS and local:checkINHEnabled($study, $dsForStudy))
    then (
      map:put($BERStudies, $updatedDS, fn:sum((map:get($BERStudies, $updatedDS), 1))), 
      map:put($BERStudies, "total", fn:sum((map:get($BERStudies, "total"), 1)))
    )
    else ()
  )
  return ()
)
return $study || ',' || $dsForStudy
)
let $_ := (
  for $ds in $dsList
  return (
    if(fn:contains($ds,"PRO1"))
    then ()
    else (
      let $dsINHEnabled := (
        for $ds in $dsForStudyConfig
        let $study := fn:tokenize($ds, ',')[1]
        let $datasource := fn:tokenize($ds, ',')[2]
        return if(local:checkINHEnabled($study, $datasource))
               then $datasource
               else ()
      )
      let $_ := (
        map:put($BERStudies, $ds, fn:count($dsINHEnabled[. eq $ds])), 
        map:put($BERStudies, "total", fn:sum((map:get($BERStudies, "total"), fn:count($dsINHEnabled[. eq $ds]))))
      )
      return ()
    )
  )
)
let $_ := map:put($response, "BERStudies", $BERStudies)

(: SOV studies :)
let $sovStudies := json:object()
let $_ := map:put($sovStudies, "total", 0)
let $_ := (
  for $ds in $dsList
  let $count := invoke-helper:execute-function-specified-database(
      function() { 
        let $_ := (
          if(fn:contains($ds,"PRO1"))
          then (
            let $studies := fn:doc(cts:uri-match("/sov/config/" || $ds || "/" || $env || "/reharmonizationconfig.xml"))//*:studies/*:study[./*:enabled/xs:string(.) eq 'true']/@Name
            let $_ := (map:put($sovStudies, "PRO1_usma", 0), map:put($sovStudies, "PRO1_PRO1", 0))
            let $_ := (
              for $s in $studies
              let $updatedDS := if(local:checkPRO1($s, $ds) eq "PRO1") then "PRO1_PRO1" else "PRO1_usma"
              let $_ := (
                map:put($sovStudies, $updatedDS, fn:sum((map:get($sovStudies, $updatedDS), 1))), 
                map:put($sovStudies, "total", fn:sum((map:get($sovStudies, "total"), 1)))
              )
              return ()
            )
            return ()
          )
          else (
            let $count := fn:count(fn:doc(cts:uri-match("/sov/config/" || $ds || "/" || $env || "/reharmonizationconfig.xml"))//*:studies/*:study[./*:enabled/xs:string(.) eq 'true'])
            return (map:put($sovStudies, $ds, $count), map:put($sovStudies, "total", fn:sum((map:get($sovStudies, "total"), $count))))          )
        )
        return 0
      },
      'sov-FINAL-LIVE', 'query'
  )
  return $count
)
let $_ := map:put($response, "sovStudies", $sovStudies)

(: SCV studies :)
let $scvStudies := json:object()
let $_ := map:put($scvStudies, "total", 0)
let $_ := (
  for $ds in $dsList
  let $count := invoke-helper:execute-function-specified-database(
      function() { 
        let $_ := (
          if(fn:contains($ds,"PRO1"))
          then (
            let $_ := (map:put($scvStudies, "PRO1_usma", 0), map:put($scvStudies, "PRO1_PRO1", 0))
            let $studies := (
                for $doc in cts:uri-match("/XYZcore/studyconfig/*/studyconfig.xml")
                let $study := fn:doc($doc)/sc:studyconfiguration/sc:studies[./@datasourceShortName eq $ds and ./@StudyEnvironment eq $env]/sc:study[./sc:status/xs:string(.) eq 'Active' and ./@enabled/xs:string(.) eq 'true']/@StudyNumber
                return $study
              )
            let $_ := (
              for $s in $studies
              let $updatedDS := if(local:checkPRO1($s, $ds) eq "PRO1") then "PRO1_PRO1" else "PRO1_usma"
              let $_ := (
                map:put($scvStudies, $updatedDS, fn:sum((map:get($scvStudies, $updatedDS), 1))), 
                map:put($scvStudies, "total", fn:sum((map:get($scvStudies, "total"), 1)))
              )
              return ()
            )
            return ()
          )
          else (
            let $count := fn:count(
                for $doc in cts:uri-match("/XYZcore/studyconfig/*/studyconfig.xml")
                let $study := fn:doc($doc)/sc:studyconfiguration/sc:studies[./@datasourceShortName eq $ds and ./@StudyEnvironment eq $env]/sc:study[./sc:status/xs:string(.) eq 'Active' and ./@enabled/xs:string(.) eq 'true']/@StudyNumber
                return $study
              )
            return (map:put($scvStudies, $ds, $count), map:put($scvStudies, "total", fn:sum((map:get($scvStudies, "total"), $count))))          )
        )
        return ()
      },
      'XYZ-FINAL-LIVE', 'query'
  )
  return $count
)
let $_ := map:put($response, "scvStudies", $scvStudies)

(: studies list :)
let $studies := json:object()
let $_ := map:put($studies, "total", 0)
let $items := (
  for $ds in $dsList
  return invoke-helper:execute-function-specified-database(
      function() { 
        for $study in fn:doc(fn:collection('latest-studyconfig-' || $ds || '-'  || $env)/base-uri(.))/*:studyconfiguration/*:studies/*:study[./*:status/xs:string(.) eq 'Active' and ./@enabled/xs:string(.) eq 'true']/@StudyNumber
        let $studyEntry := json:object()
        let $ingestion := invoke-helper:execute-function-specified-database(
            function() { 
              if(local:checkINHEnabled($study, $ds))
              then "YES"
              else "NO"
            },
            'XYZ-FINAL-LIVE', 'query'
        )
        let $BER := invoke-helper:execute-function-specified-database(
            function() { 
              let $doc := fn:doc(cts:uri-match("/saegeneration/config/StudyConfig.json"))
              return if($doc/Studies[./study/xs:string(.) eq $study and ./active/xs:string(.) eq "ON"])
              then "YES"
              else "NO"
            },
            'BER-FINAL-LIVE', 'query'
        )
        let $sov := invoke-helper:execute-function-specified-database(
            function() { 
              let $sovStudy := fn:doc(cts:uri-match("/sov/config/" || $ds || "/" || $env || "/reharmonizationconfig.xml"))//*:studies/*:study[./@Name eq $study]
              let $exists := if($sovStudy/*:enabled/xs:string(.) eq 'true') then "YES" else "NO"
              return $exists
            },
            'sov-FINAL-LIVE', 'query'
        )
        let $scv := invoke-helper:execute-function-specified-database(
            function() { 
              if(local:checkINHEnabled($study, $ds))
              then "YES"
              else "NO"
            },
            'XYZ-FINAL-LIVE', 'query'
        )
        
        
        let $_ := map:put($studyEntry, 'studyName', $study)
        let $_ := map:put($studyEntry, 'ds', fn:upper-case(local:checkPRO1($study, $ds)))
        let $_ := map:put($studyEntry, 'ingestion', $ingestion)
        let $_ := map:put($studyEntry, 'sov', $sov)
        let $_ := map:put($studyEntry, 'BER', $BER)
        let $_ := map:put($studyEntry, 'scv', $scv)
        let $_ := map:put($studies, "total", fn:sum((map:get($studies, "total"), 1)))
        return $studyEntry
      },
      'XYZ-FINAL-LIVE', 'query'
  )
)

let $sortedItems := json:to-array(
  for $item in $items
  order by map:get($item, "studyName")
  return $item)


let $_ := map:put($studies, "items", $sortedItems)
let $_ := map:put($response, "studies", $studies)

return xdmp:to-json($response)
