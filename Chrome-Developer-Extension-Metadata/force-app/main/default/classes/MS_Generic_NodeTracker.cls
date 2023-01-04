@RestResource(urlMapping='/nodeTracker/search')
global without sharing  class MS_Generic_NodeTracker {
    
    public static String CONST_NS =  MS_Generic_DataUtilityHelper.CONST_NS; 
    public static  final List<String>  LIST_OF_INPUTNODE_TYPE       =   new List<String>{'Set Values','Checkbox','Currency','Date','Date/Time (Local)','Email','File','Filter','Formula','Geolocation','Image','Lookup','Multi-select','Number','Password','Radio','Radio Group','Range','Select','Selectable Items','Text','Text Area','Time' ,'URL' };
    public static String  CONSTANT_DYNAMIC_QUERY      = '';
    public static String  CONSTANT_FIELD_NAMES        = ' Id, Name, '+CONST_NS+'SubType__c, '+CONST_NS+'Type__c, '+CONST_NS+'IsProcedure__c,'+CONST_NS+'Version__c,'+CONST_NS+'IsActive__c ';
    public static String  CONSTANT_QUERY_CONDITION    = ' where (Id =:searchText OR Name like :searchText OR  '+CONST_NS+'Type__c like :searchText OR '+CONST_NS+'SubType__c like :searchText ) ';
    
     @HttpPost 
    global static String  postNodeTrackDetails(String methodName, String inputMap){
        Map<String,Object> mapOfInput = new Map<String,Object>();
       
        if(String.isNotBlank(inputMap)){
            mapOfInput = (Map<String,Object>)JSON.deserializeUntyped(inputMap);
        }
        
        if(methodName.equalsIgnoreCase('getOmniscriptComponents')){
           return System.JSON.serialize(getOmniscriptComponents((String)mapOfInput.get('Id')));
        }
        else if(methodName.equalsIgnoreCase('trackNode')){
            String recordId = (String)mapOfInput.get('recordId'); 
            Boolean isOmniscript=(Boolean)mapOfInput.get('isOmniscript'); 
            String nodeType =(String)mapOfInput.get('nodeType');
            List<Id> searchOnlyElements = (List<Id>)JSON.deserialize(JSON.serialize(mapOfInput.get('searchOnlyElements')), List<Id>.class);
            List<String> inputNodeList =(List<String>)  JSON.deserialize(JSON.serialize(mapOfInput.get('inputNodeList')), List<String>.class);
            Map<String,Object> options =(Map<String,Object>)mapOfInput.get('options');
            return System.JSON.serialize(trackNode(recordId,isOmniscript,nodeType,searchOnlyElements,inputNodeList,options));
        }
        else if (methodName.equalsIgnoreCase('getExtnApexVersion')){
            ExtensionApexVersionDetail detail = new ExtensionApexVersionDetail();
            detail.Version = MS_Generic_DataUtilityHelper.CONSTANT_EXTENSION_APEX_VERSION;
            return System.JSON.serialize(detail);
        }
        
        return '';
    }
    
     
    
   // 
    @AuraEnabled
    public  static String  getListOfOmniscript( String searchText ,Boolean isIntegrationProcedure){ 
        searchText = String.escapeSingleQuotes(searchText);
       
        if(searchText.contains('/')){
            List<String> typeSubtypeList =  searchText.split('/');
            
            if(typeSubtypeList.size()>0){
                CONSTANT_QUERY_CONDITION =' where ( '+CONST_NS+'Type__c =\''+ typeSubtypeList[0]+'\''; 
            }
            if(typeSubtypeList.size()>1){
                CONSTANT_QUERY_CONDITION +='and '+CONST_NS+'SubType__c like \'%'+ typeSubtypeList[1] +'%\' )'; 
            }else{
                CONSTANT_QUERY_CONDITION +=' ) ';
            }
            
        } else {
            if(!(searchText instanceof Id)){
                searchText ='%' +searchText+'%';
                
            }
        }
        
        CONSTANT_QUERY_CONDITION += ' AND ( '+CONST_NS+'IsProcedure__c ='+isIntegrationProcedure+ ' ) '; 
        
        
        CONSTANT_DYNAMIC_QUERY =' Select ' + CONSTANT_FIELD_NAMES + 'from '+CONST_NS+'OmniScript__c'+ CONSTANT_QUERY_CONDITION +' order by Name';
       // return (List<SObject>) Database.query(CONSTANT_DYNAMIC_QUERY);
        
          List<Omniscript> listElementsRetrieved = new List<Omniscript>();
        for(Sobject sObj : Database.query(CONSTANT_DYNAMIC_QUERY)){
        Omniscript omniObj = new Omniscript();
            omniObj.Id       = (String) sObj.get('Id');
            omniObj.Name     = (String) sObj.get('Name');
            omniObj.OsType   = (String) sObj.get(CONST_NS+ 'Type__c');
            omniObj.SubType  = (String) sObj.get(CONST_NS+ 'SubType__c'); 
            omniObj.IsActive = (Boolean)sObj.get(CONST_NS+ 'IsActive__c');
            omniObj.Version  = (Double) sObj.get(CONST_NS+ 'Version__c'); 
            omniObj.IsProcedure  = (Boolean) sObj.get(CONST_NS+ 'IsProcedure__c'); 
            listElementsRetrieved.add(omniObj);
        }
        
         return  JSON.serialize(listElementsRetrieved);
        
        } 
    
   
    /* Get  omniscript elements by omniscript Id  */
    @AuraEnabled
    public static Map<Id,OmniscriptElement>  getOmniscriptComponents(String omniscriptId){
        
               omniscriptId =String.escapeSingleQuotes(omniscriptId);

        String queryStr = 'SELECT Id, Name,'+CONST_NS+'Order__c, '+CONST_NS+'OmniScriptId__r.'+CONST_NS+ 'IsProcedure__c, '+CONST_NS+'OmniScriptId__c, '+CONST_NS+'ParentElementId__c, '+CONST_NS+'Type__c,'+CONST_NS+'ParentElementType__c, '+CONST_NS+'ParentElementName__c from '+CONST_NS+'Element__c where '+CONST_NS+'OmniScriptId__c =:omniscriptId order by  '+CONST_NS+'Order__c ASC'; 
  
        Map<Id, OmniscriptElement> mapOfOmniscriptElement = new Map<Id, OmniscriptElement>();
       
        for(Sobject sObj : Database.query(queryStr)){
            OmniscriptElement omniElementObj = new OmniscriptElement();
            omniElementObj.Id       = (String) sObj.get('Id');
            omniElementObj.Name     = (String) sObj.get('Name');
            omniElementObj.ElementType   = (String) sObj.get(CONST_NS+ 'Type__c');
            omniElementObj.ParentElementId  = (String) sObj.get(CONST_NS+ 'ParentElementId__c'); 
            omniElementObj.elementOrder =(Double) sObj.get(CONST_NS+ 'Order__c'); 
           
            Sobject omniscriptReference= sObj.getSObject(CONST_NS+'OmniScriptId__r');
            omniElementObj.isParentIP = (Boolean) omniscriptReference.get(CONST_NS+ 'IsProcedure__c'); 
            mapOfOmniscriptElement.put(omniElementObj.Id, omniElementObj);
        }
        
        return mapOfOmniscriptElement ;

        
    }
    
    /** search only elements for extension used in Chrome extension**/
     @auraEnabled
    public static  List<JSONNodeReferrenceWrapper> trackNode( String recordId , Boolean isOmniscript, String nodeType, List<Id> searchOnlyElements, List<String> inputNodeList ,Map<String,Object> options){ 
          return MS_Generic_NodeTracker.trackSetValueMap(recordId,isOmniscript ,nodeType, searchOnlyElements, inputNodeList, options);      
    }
    
     /** with Start and End elements for existing used in Lightning component **/
    @auraEnabled
    public static  List<JSONNodeReferrenceWrapper> trackNode( String recordId , Boolean isOmniscript, String nodeType, List<Id> startElementIds ,  List<String> endElementIds ,List<String> inputNodeList ,Map<String,Object> options){ 
        List<Id> searchOnlyElements = new List<Id>();
        if(startElementIds == null){
            startElementIds = new List<Id>();
        }
        if(endElementIds == null){
            endElementIds   = new List<Id>();
        }
       // uncomment only when it is needed searchOnlyElements = MS_DependencyEliminateContoller.filterHigherHeirarchyElements( recordId, null , endElementIds , startElementIds, true);
        return MS_Generic_NodeTracker.trackSetValueMap(recordId,isOmniscript ,nodeType, searchOnlyElements, inputNodeList, options);
        
    }
    
    @auraEnabled
    public static  List<JSONNodeReferrenceWrapper> trackSetValueMap( String recordId , Boolean isOmniscript, String nodeType, List<String> searchOnlyElements , List<String> inputNodeList ,Map<String,Object> options){ 
        if(inputNodeList == null || inputNodeList.isEmpty() ){
            return new List<JSONNodeReferrenceWrapper>();
        }
        
        List<Sobject> elementResponse = new List<Sobject>();
        List<JSONNodeReferrenceWrapper> listOfMatchedElementWrapper = new List<JSONNodeReferrenceWrapper>();
        
        Set<String> setOfReservedElement = new Set<String> ();
        Set<String> listOsType = new Set<String>();
        Set<String> listOsSubType = new Set<String>();
        Set<String> listOfIntegrationProcedureKey = new Set<String>();
        
        Map<String ,List<String>> mapOfTypeSubTypeAndElementName = new Map<String ,List<String>> () ;
        Map<String ,List<String>> mapOfTypeSubTypeAndElementNameVIP = new Map<String ,List<String>> () ;
        Map<String ,JSONNodeReferrenceWrapper> mapOfElementAndElementWrapper = new Map<String ,JSONNodeReferrenceWrapper> () ; 
        
        Boolean deepSearchOS  = options.containsKey('deepSearch_ReUsable_OS') && (Boolean) options.get('deepSearch_ReUsable_OS');
        Boolean deepSearchVIP = options.containsKey('deepSearch_VIP') && (Boolean) options.get('deepSearch_VIP');
       
        String query = MS_Generic_DataUtilityHelper.FIELD_NAME_OS_ELEMENT+' from '+CONST_NS+'Element__c';
        String whereCondition = ' where '+CONST_NS+'OmniScriptId__c =:recordId ';
        
       // whereCondition +=' and ( '+CONST_NS+'Type__c =\'Set Values\' ) '; // 
        
        if(searchOnlyElements != null && !searchOnlyElements.isEmpty()){
            
            whereCondition += ' and ( Id IN: searchOnlyElements ) '; 
        }
        whereCondition += ' and ( '+CONST_NS+'Type__c IN :LIST_OF_INPUTNODE_TYPE '; // Changes made on 8 september 2021
        if(deepSearchOS){
            whereCondition += ' OR '+CONST_NS+'Type__c =\'OmniScript\' '; 
        }
        if(deepSearchVIP){
            whereCondition += ' OR '+CONST_NS+'Type__c =\'Integration Procedure Action\' '; 
        }
        whereCondition += ')';
        String Orderby = ' order by '+CONST_NS+'Order__c ASC ';
        
        
        if(nodeType.endsWithIgnoreCase(MS_Generic_DataUtilityHelper.LABEL_SET_VALUE_ELEMENT)){
            
            String  regexCheckNodeEmpty = '(\\s*"\\s*elementValueMap\\s*"\\s*:\\s*\\{\\s*\\})';
            String regexExpForInputNodeToCheck = MS_Generic_DataUtilityHelper.getRegExpForInputNodes( MS_Generic_DataUtilityHelper.DEFAULT_JSON_REGEX_PATTERN , MS_Generic_DataUtilityHelper.DEFAULT_INPUT_NODE_REGEX_PATTERN , inputNodeList ,'elementValueMap', MS_Generic_DataUtilityHelper.LABEL_SET_VALUE_ELEMENT);
            String regexExpGetIntegrationProcedureKey ='(\\s*"\\s*integrationProcedureKey\\s*"\\s*:\\s*"\\s*[A-Za-z0-9\\_-]+\\s*")';
            
            elementResponse = (List<Sobject>) DataBase.query(query + whereCondition + Orderby);
            
            for(Sobject setElement : elementResponse ){
               String elementName= (String) setElement.get('Name');
               String elementPropertySet= (String) setElement.get(CONST_NS+'PropertySet__c');
                
                if(deepSearchOS &&  MS_Generic_DataUtilityHelper.isOmniscriptElement(setElement)){
                    List<String> typeSubTypeLanguage = new List<String>(((String)setElement.get(CONST_NS+'SearchKey__c')).split('\\|'));
                    String type_subType  = typeSubTypeLanguage.get(0)+'_'+typeSubTypeLanguage.get(1);
                    listOsType.add(typeSubTypeLanguage.get(0)); 
                    listOsSubType.add(typeSubTypeLanguage.get(1)); 
                    if(mapOfTypeSubTypeAndElementName.containsKey(type_subType)){
                        mapOfTypeSubTypeAndElementName.get(type_subType).add(elementName);
                    }else{
                        mapOfTypeSubTypeAndElementName.put(type_subType , new List<String>{elementName});  
                    }
                    
                    mapOfElementAndElementWrapper.put(elementName , new JSONNodeReferrenceWrapper(setElement));
                }
                
                if(deepSearchVIP && MS_Generic_DataUtilityHelper.isIntegrationProcedureElement(setElement)){
                    String integrationProcedureKey = MS_Generic_DataUtilityHelper.getIntegrationProcedureName(elementPropertySet ,regexExpGetIntegrationProcedureKey);
                    listOfIntegrationProcedureKey.add(integrationProcedureKey);
                    if(mapOfTypeSubTypeAndElementNameVIP.containsKey(integrationProcedureKey)){
                        mapOfTypeSubTypeAndElementNameVIP.get(integrationProcedureKey).add(elementName);
                    }else{
                        mapOfTypeSubTypeAndElementNameVIP.put(integrationProcedureKey,new List<String>{elementName});
                    }
                    
                    mapOfElementAndElementWrapper.put(elementName , new JSONNodeReferrenceWrapper(setElement));
                    
                }
                if(MS_Generic_DataUtilityHelper.isSetValueElement(setElement)){
                    if(!MS_Generic_DataUtilityHelper.isPatternMatchFound(regexCheckNodeEmpty,elementPropertySet) && MS_Generic_DataUtilityHelper.isPatternMatchFound(regexExpForInputNodeToCheck,elementPropertySet)){
                        mapOfElementAndElementWrapper.put(elementName , new JSONNodeReferrenceWrapper(setElement));
                    }    
                }else if(inputNodeList.contains(elementName) && LIST_OF_INPUTNODE_TYPE.contains((String)setElement.get(CONST_NS+'Type__c'))){
                    mapOfElementAndElementWrapper.put(elementName , new JSONNodeReferrenceWrapper(setElement));
                    
                }
            } 
            
            
        }  
        
        else if (nodeType == 'JSONReference'){
            String  regexExpForConditionalGroup = MS_Generic_DataUtilityHelper.getRegexJSONReferenceNode('show', inputNodeList);
            String  regexExpForJSONReference    = MS_Generic_DataUtilityHelper.getRegexJSONReferenceNode('', inputNodeList);
            
            for(SObject setElement : Database.query('SELECT Id, Name,'+CONST_NS+'SearchKey__c, '+CONST_NS+'Active__c,'+CONST_NS+'Order__c, '+CONST_NS+'OmniScriptId__c, '+CONST_NS+'PropertySet__c, '+CONST_NS+'Type__c FROM '+CONST_NS+'Element__c where '+CONST_NS+'OmniScriptId__c=:recordId order by '+CONST_NS+'Order__c ASC')){
                if(searchOnlyElements.contains(setElement.Id) || searchOnlyElements.isEmpty()){
                    
                    
                    Boolean isConditionalGroup = MS_Generic_DataUtilityHelper.isPatternMatchFound(regexExpForConditionalGroup,(String)setElement.get(CONST_NS+'PropertySet__c'));
                    Boolean isJSONNodeRefered  = MS_Generic_DataUtilityHelper.isPatternMatchFound(regexExpForJSONReference, (String)setElement.get(CONST_NS+'PropertySet__c'));
                    String elementName = (String)setElement.get('Name');
                    if( isConditionalGroup || isJSONNodeRefered ){
                        JSONNodeReferrenceWrapper responseObj = new JSONNodeReferrenceWrapper(setElement);
                        responseObj.isConditionalGroup = isConditionalGroup;
                        responseObj.isJSONNodeRefered = isJSONNodeRefered;  
                        mapOfElementAndElementWrapper.put(elementName , responseObj);
                        setOfReservedElement.add(elementName);
                    }
                    
                    if(isOmniscript && deepSearchOS && ((String)setElement.get(CONST_NS+'Type__c')).endsWithIgnoreCase('OmniScript')){
                        List<String> typeSubTypeLanguage = new List<String>(((String)setElement.get(CONST_NS+'SearchKey__c')).split('\\|'));
                        listOsType.add(typeSubTypeLanguage.get(0)); 
                        listOsSubType.add(typeSubTypeLanguage.get(1)); 
                        String type_subType = typeSubTypeLanguage.get(0)+'_'+typeSubTypeLanguage.get(1);
                        if(mapOfTypeSubTypeAndElementName.containsKey(type_subType)){
                            mapOfTypeSubTypeAndElementName.get(type_subType).add(elementName);
                        }else{
                            mapOfTypeSubTypeAndElementName.put(type_subType ,new List<String>{elementName});  
                        }
                        if( (!isConditionalGroup && !isJSONNodeRefered) ){
                            mapOfElementAndElementWrapper.put(elementName , new JSONNodeReferrenceWrapper(setElement)); 
                        }
                        
                    }
                    
                } 
            }
            
        }
        else if(nodeType == 'TrackAnyNode'){
             String  regexExpForAnyNode    = MS_Generic_DataUtilityHelper.getRegExpForInputNodes(MS_Generic_DataUtilityHelper.DEFAULT_MAIN_REGEX_PATTERN_ANY_NODE ,MS_Generic_DataUtilityHelper.DEFAULT_INPUT_REGEX_PATTERN_ANY_NODE, inputNodeList,'',MS_Generic_DataUtilityHelper.LABEL_TRACK_ANY_NODE);
            
            for(SObject setElement : Database.query('SELECT Id, Name,'+CONST_NS+'SearchKey__c, '+CONST_NS+'Active__c,'+CONST_NS+'Order__c, '+CONST_NS+'OmniScriptId__c, '+CONST_NS+'PropertySet__c,'+CONST_NS+'Type__c FROM '+CONST_NS+'Element__c where '+CONST_NS+'OmniScriptId__c=:recordId order by '+CONST_NS+'Order__c ASC')){
            
                if(searchOnlyElements.contains((String)setElement.get('Id'))  || searchOnlyElements.isEmpty() ){ 
                    Boolean isMatchFound = MS_Generic_DataUtilityHelper.isPatternMatchFound(regexExpForAnyNode,(String)setElement.get(CONST_NS+'PropertySet__c'));
                    String elementName =(String) setElement.get('Name');
                    
                    if(isMatchFound){
                        mapOfElementAndElementWrapper.put(elementName , new JSONNodeReferrenceWrapper(setElement));
                        setOfReservedElement.add(elementName);  
                    }
                    
                    if(isOmniscript && deepSearchOS && ((String)setElement.get(CONST_NS+'Type__c')).endsWithIgnoreCase('OmniScript')){ 
                        List<String> typeSubTypeLanguage = new List<String>(((String)setElement.get(CONST_NS+'SearchKey__c')).split('\\|'));
                        listOsType.add(typeSubTypeLanguage.get(0)); 
                        listOsSubType.add(typeSubTypeLanguage.get(1)); 
                        String type_subType = typeSubTypeLanguage.get(0)+'_'+typeSubTypeLanguage.get(1);
                        if(mapOfTypeSubTypeAndElementName.containsKey(type_subType)){
                            mapOfTypeSubTypeAndElementName.get(type_subType).add(elementName);
                        }else{
                            mapOfTypeSubTypeAndElementName.put(type_subType ,new List<String>{elementName});  
                        }
                        if( !isMatchFound ){
                            mapOfElementAndElementWrapper.put(elementName , new JSONNodeReferrenceWrapper(setElement)); 
                        }
                        
                    }
                }
            }
        }
      
        /** Execute for All Deep search **/
        if(!listOsType.isEmpty() && !listOsSubType.isEmpty()){
            if(nodeType.endsWithIgnoreCase('JSONReference')  ){
                deepSearchJSONNode (inputNodeList, listOsType, listOsSubType, mapOfElementAndElementWrapper, mapOfTypeSubTypeAndElementName,setOfReservedElement);   
            }
            if(nodeType.endsWithIgnoreCase(MS_Generic_DataUtilityHelper.LABEL_SET_VALUE_ELEMENT)){
                deepSearchOmniscript (inputNodeList, listOsType, listOsSubType, mapOfElementAndElementWrapper, mapOfTypeSubTypeAndElementName);   
            }
            if(nodeType.endsWithIgnoreCase('TrackAnyNode')){
                deepSearchAnyNode (inputNodeList, listOsType, listOsSubType, mapOfElementAndElementWrapper, mapOfTypeSubTypeAndElementName,setOfReservedElement);   
            }
        }
        
        if(!listOfIntegrationProcedureKey.isEmpty()){
            deepSearchJSONNodeVIP(inputNodeList , listOfIntegrationProcedureKey , mapOfElementAndElementWrapper, mapOfTypeSubTypeAndElementNameVIP);
        }
         /** Execute for All Deep search **/
        
       return mapOfElementAndElementWrapper.values(); 
    }
    
    
    public static  void  deepSearchOmniscript (List<String>inputNodeList ,Set<String> listOfType ,Set<String> listOfSubType,Map<String ,JSONNodeReferrenceWrapper> mapOfResponse, Map<String, List<String>> mapOfTypeSubTypeAndElementName){
        
        String  regexCheckNodeEmpty = '(\\s*"\\s*elementValueMap\\s*"\\s*:\\s*\\{\\s*\\})';
        String regexExpForInputNodeToCheck = MS_Generic_DataUtilityHelper.getRegExpForInputNodes(MS_Generic_DataUtilityHelper.DEFAULT_JSON_REGEX_PATTERN ,  MS_Generic_DataUtilityHelper.DEFAULT_INPUT_NODE_REGEX_PATTERN ,inputNodeList , 'elementValueMap', MS_Generic_DataUtilityHelper.LABEL_SET_VALUE_ELEMENT);
       
        String query = MS_Generic_DataUtilityHelper.FIELD_NAME_OS_ELEMENT+MS_Generic_DataUtilityHelper.RELATIONAL_FIELD_NAME_OS_OS_ELEMENT +' from '+CONST_NS+'Element__c';
        String whereCondition =' where '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsActive__c = true and  '+CONST_NS+'Type__c =\''+'Set Values'+'\' and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c in :listOfType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c in :listOfSubType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsReusable__c= true';
        String Orderby =' order by '+CONST_NS+'Order__c ASC';
        
        List<Sobject> elementResponse = new List<Sobject>();
        Set<String> matchedOmniscript = new Set<String>(); 
        List<String> listOfRegexToMatch = new List<String>{regexExpForInputNodeToCheck};
        
        elementResponse = (List<Sobject>) DataBase.query(query+whereCondition+Orderby);
        genericMethodSetMatchedNode( elementResponse , mapOfResponse, mapOfTypeSubTypeAndElementName, listOfRegexToMatch,null );
        
        whereCondition =' where '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsActive__c = true and  '+CONST_NS+'Type__c =\''+MS_Generic_DataUtilityHelper.LABEL_VIP_ELEMENT+'\' and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c in :listOfType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c in :listOfSubType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsReusable__c= true';
        elementResponse = (List<Sobject>) DataBase.query(query+whereCondition+Orderby);
        String regexExpGetIntegrationProcedureKey ='(\\s*"\\s*integrationProcedureKey\\s*"\\s*:\\s*"\\s*[A-Za-z0-9\\_-]+\\s*")';

        for(Sobject element : elementResponse ){
            String integrationProcedureKey = MS_Generic_DataUtilityHelper.getIntegrationProcedureName((String)element.get(CONST_NS+'PropertySet__c') ,regexExpGetIntegrationProcedureKey);
          //  listOfIntegrationProcedureKey.add(integrationProcedureKey);
          //  if(mapOfTypeSubTypeAndElementNameVIP.containsKey(integrationProcedureKey)){
            //    mapOfTypeSubTypeAndElementNameVIP.get(integrationProcedureKey).add(setElement.Name);
           // } else {
           //     mapOfTypeSubTypeAndElementNameVIP.put(integrationProcedureKey,new List<String>{setElement.Name});
          //  }
            
           // mapOfElementAndElementWrapper.put(setElement.Name , new JSONNodeReferrenceWrapper(setElement));
            
        }
        
   
    }
    
    public static  void deepSearchJSONNode(List<String>inputNodeList ,Set<String> listOfType ,Set<String> listOfSubType,Map<String ,JSONNodeReferrenceWrapper> mapOfResponse, Map<String, List<String>> mapOfTypeSubTypeAndElementName, Set<String>  setOfReservedElement  ){
      
        String  regexCheckNodeEmpty = '(\\s*"\\s*elementValueMap\\s*"\\s*:\\s*\\{\\s*\\})';
        String  regexExpForInputNodeToCheck = MS_Generic_DataUtilityHelper.getRegExpForInputNodes( MS_Generic_DataUtilityHelper.DEFAULT_JSON_REGEX_PATTERN , MS_Generic_DataUtilityHelper.DEFAULT_INPUT_NODE_REGEX_PATTERN , inputNodeList , 'elementValueMap','');
        String  regexExpForConditionalGroup = MS_Generic_DataUtilityHelper.getRegexJSONReferenceNode('show', inputNodeList);
        String  regexExpForJSONReference    = MS_Generic_DataUtilityHelper.getRegexJSONReferenceNode('', inputNodeList);
       
        List<String> listOfRegexToMatch = new List<String>{regexExpForConditionalGroup,regexExpForJSONReference};
        String queryStr ='SELECT Id, Name, '+CONST_NS+'Active__c, '+CONST_NS+'Order__c,'+CONST_NS+'OmniScriptId__c, '+CONST_NS+'PropertySet__c, '+CONST_NS+'Type__c,'+CONST_NS+'SearchKey__c ,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c  FROM '+CONST_NS+'Element__c where '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsActive__c= true  and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c in :listOfType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c in :listOfSubType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsReusable__c= true order by '+CONST_NS+'Order__c ASC ';
        List<Sobject> listOfOSElement = Database.query(queryStr);
        genericMethodSetMatchedNode( listOfOSElement , mapOfResponse, mapOfTypeSubTypeAndElementName, listOfRegexToMatch,setOfReservedElement );
      }
    
    public static  void deepSearchJSONNodeVIP(List<String>inputNodeList ,Set<String> listOfIntegrationProcedureKey ,Map<String ,JSONNodeReferrenceWrapper> mapOfResponse, Map<String, List<String>> mapOfTypeSubTypeAndElementName){
        String  regexCheckNodeEmpty = '(\\s*"\\s*elementValueMap\\s*"\\s*:\\s*\\{\\s*\\})';
        String regexExpForResponseAllNode =  MS_Generic_DataUtilityHelper.getRegExpForInputNodes(MS_Generic_DataUtilityHelper.REGEX_VIP_RESPONSE_ACTION_PATTERN_MAIN,
                                                                                             MS_Generic_DataUtilityHelper.REGEX_VIP_RESPONSE_ACTION_PATTERN_INPUT,
                                                                                             inputNodeList, 'additionalOutput','');
        String regexExpForResponseNode  =  MS_Generic_DataUtilityHelper.getRegExpForInputNodes(MS_Generic_DataUtilityHelper.REGEX_VIP_RESPONSE_NODE_PATTERN_MAIN,
                                                                                           MS_Generic_DataUtilityHelper.REGEX_VIP_RESPONSE_NODE_PATTERN_INPUT,
                                                                                           inputNodeList, 'sendJSONNode','');
        
        Set<String> matchedOmniscript = new Set<String>(); 
        String finalRegexForDeepsearch = regexExpForResponseAllNode+'|'+regexExpForResponseNode;
        List<String> listOfRegexToMatch = new List<String>{finalRegexForDeepsearch};
        String queryStr ='SELECT Id, Name, '+CONST_NS+'Active__c, '+CONST_NS+'Order__c,'+CONST_NS+'OmniScriptId__c,'+CONST_NS+'PropertySet__c, '+CONST_NS+'Type__c,'+CONST_NS+'SearchKey__c ,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'ProcedureKey__c,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c   FROM '+CONST_NS+'Element__c where '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsActive__c= true and  '+CONST_NS+'Type__c =\'Response Action\' and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsProcedure__c  = true and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'ProcedureKey__c in :listOfIntegrationProcedureKey order by '+CONST_NS+'Order__c ASC';
        List<Sobject> listOfOSElement = Database.query(queryStr);
        
        genericMethodSetMatchedNode( listOfOSElement , mapOfResponse, mapOfTypeSubTypeAndElementName, listOfRegexToMatch, null);
        
    }
    
    public static  void deepSearchAnyNode(List<String>inputNodeList ,Set<String> listOfType ,Set<String> listOfSubType,Map<String ,JSONNodeReferrenceWrapper> mapOfResponse, Map<String, List<String>> mapOfTypeSubTypeAndElementName, Set<String>  setOfReservedElement  ){
        String  regexExpForAnyNode    = MS_Generic_DataUtilityHelper.getRegExpForInputNodes(MS_Generic_DataUtilityHelper.DEFAULT_MAIN_REGEX_PATTERN_ANY_NODE ,MS_Generic_DataUtilityHelper.DEFAULT_INPUT_REGEX_PATTERN_ANY_NODE, inputNodeList,'',MS_Generic_DataUtilityHelper.LABEL_TRACK_ANY_NODE);
        List<String> listOfRegexToMatch = new List<String>{regexExpForAnyNode};
        String queryStr ='SELECT Id, Name, '+CONST_NS+'Active__c, '+CONST_NS+'Order__c,'+CONST_NS+'OmniScriptId__c, '+CONST_NS+'PropertySet__c, '+CONST_NS+'Type__c,'+CONST_NS+'SearchKey__c ,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c  FROM '+CONST_NS+'Element__c where '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsActive__c= true  and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c in :listOfType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c in :listOfSubType and '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'IsReusable__c= true order by '+CONST_NS+'Order__c ASC ';
        List<Sobject> listOfOSElement = database.query(queryStr);
        genericMethodSetMatchedNode( listOfOSElement , mapOfResponse, mapOfTypeSubTypeAndElementName, listOfRegexToMatch,setOfReservedElement );
        
    }
   
    public static  void genericMethodSetMatchedNode(List<SObject> listOfOSElement ,Map<String ,JSONNodeReferrenceWrapper> mapOfResponse,Map<String, List<String>> mapOfTypeSubTypeAndElementName,List<String> listOfRegexToMatch,Set<String>  setOfReservedElement  ){
        Set<String> matchedOmniscript = new Set<String>(); 
      
        if(listOfOSElement != null){
            for(SObject setElement : listOfOSElement){
                Boolean isMatchFound = false;
                for(String regexToVerify : listOfRegexToMatch){
                    isMatchFound =   isMatchFound  || MS_Generic_DataUtilityHelper.isPatternMatchFound(regexToVerify,(String)setElement.get(CONST_NS+'PropertySet__c'));
                }
                if(isMatchFound){
                    Sobject omniscriptReference= setElement.getSObject(CONST_NS+'OmniScriptId__r');
                    String typeSubType = omniscriptReference.get(CONST_NS+'Type__c')+'_'+omniscriptReference.get(CONST_NS+'SubType__c') ;
                    matchedOmniscript.add(typeSubType);
                    for(String os_typeSubType : mapOfTypeSubTypeAndElementName.get(typeSubType)){
                        mapOfResponse.get(os_typeSubType).childOsElements.add(new JSONNodeReferrenceWrapper(setElement));
                        mapOfResponse.get(os_typeSubType).OminiscriptId = (String)setElement.get(CONST_NS+'OmniScriptId__c');
                    }
                }
            }
        }
        
        for(String allOS_TypeSubtype : mapOfTypeSubTypeAndElementName.Keyset()){
            if(! matchedOmniscript.contains(allOS_TypeSubtype)){
                for(String elementName : mapOfTypeSubTypeAndElementName.get(allOS_TypeSubtype)){
                    if(setOfReservedElement != Null){
                        if(!setOfReservedElement.contains(elementName)) {
                            mapOfResponse.remove(elementName);
                        }  
                    }else{
                        mapOfResponse.remove(elementName);
                    }
                }
            }
        }
    } 
    
    
    public  Class JSONNodeReferrenceWrapper {
        @auraEnabled public string    name = '';
        @auraEnabled public String    Id = '';
        @auraEnabled public String    OminiscriptId = '';
        @auraEnabled public String    elementType = '';
        @auraEnabled public Double    elementOrder = 0;
        @auraEnabled public String    propertySetJSON = '';
        @auraEnabled public Boolean   isActive = false;
        @auraEnabled public Boolean   isConditionalGroup;
        @auraEnabled public Boolean   isJSONNodeRefered ; 
        @auraEnabled public Boolean   showChildNodes =false; 
        @auraEnabled public String   nameSpace =  CONST_NS; 
        
        @auraEnabled public List<JSONNodeReferrenceWrapper>   childOsElements = new List<JSONNodeReferrenceWrapper> () ; 
        
        
        public JSONNodeReferrenceWrapper(Sobject vElement){
            this.name            = (String)vElement.get('Name');
            this.Id              = (String)vElement.get('Id');
            this.elementType     = (String)vElement.get(CONST_NS+'Type__c');
            this.propertySetJSON = (String)vElement.get(CONST_NS+'PropertySet__c');
            this.isActive        = (Boolean)vElement.get(CONST_NS+'Active__c');
            this.elementOrder    = (Double)vElement.get(CONST_NS+'Order__c');
        }   
        
    }
    
     public class Omniscript {
        @AuraEnabled public String  Id = '';
        @AuraEnabled public String  Name = '';
        @AuraEnabled public String  OsType = '';
        @AuraEnabled public String  SubType= '';
        @AuraEnabled public boolean IsActive ;
        @AuraEnabled public Double  Version ;
        @AuraEnabled public Boolean  IsProcedure = false;   
     }
    
    public class OmniscriptElement {
        @AuraEnabled public String  Id = '';
        @AuraEnabled public String  Name = '';
        @AuraEnabled public String  ElementType ;
        @AuraEnabled public String  ParentElementId ;
        @AuraEnabled public Double  elementOrder ;
        @AuraEnabled public Boolean  isParentIP ;
           }
    
    public class ExtensionApexVersionDetail {
         @AuraEnabled public String  Version = '';
      @AuraEnabled public String  ClassName = 'MS_Generic_NodeTracker';
        
    }
    
}