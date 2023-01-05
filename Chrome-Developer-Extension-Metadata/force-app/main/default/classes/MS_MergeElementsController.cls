@RestResource(urlMapping='/ms_osip/elements/merge')

global with sharing class MS_MergeElementsController {
 
    public static String CONST_NS =  MS_Generic_DataUtilityHelper.getCurrentNameSpace();
   
    public static Set<String> setOfNameOfDestinationOSElements = new Set<String>();
    public static String  CONSTANT_DYNAMIC_QUERY      = '';
    public static String  CONSTANT_FIELD_NAMES        = ' Id, Name, '+CONST_NS+'SubType__c, '+CONST_NS+'Type__c, '+CONST_NS+'IsProcedure__c,'+CONST_NS+'Version__c,'+CONST_NS+'IsActive__c ';
    public static String  CONSTANT_QUERY_CONDITION    = ' where (Id =:searchText OR Name like :searchText OR  '+CONST_NS+'Type__c like :searchText OR '+CONST_NS+'SubType__c like :searchText ) ';
    public static Integer CONSTANT_MAXIMUM_DML_COUNT  = 145;
    public static List<String> CONSTANT_INPUTNODE_COMBINATION      =  new List<String>();
    public static List<Id> OUTPUT_LIST_OF_BIND_EXPRESSION_ELEMENTS =  new List<Id>();
    
   
    
     @HttpPost 
    global static String  postOmniMergeInvoke(String methodName, String inputMap){
        Map<String,Object> mapOfInput = new Map<String,Object>();
       
        if(String.isNotBlank(inputMap)){
            mapOfInput = (Map<String,Object>)JSON.deserializeUntyped(inputMap);
        }
        if(methodName.equalsIgnoreCase('getAllOmniscriptComponents')){
            return System.JSON.serialize(getAllOmniscriptComponents((String)mapOfInput.get('searchText'),(Boolean)mapOfInput.get('destinationQuery'),(Boolean)mapOfInput.get('elementTypeIP')));
        }
        else if(methodName.equalsIgnoreCase('getOmniscriptElements')){
           return System.JSON.serialize(getOmniscriptComponents((String)mapOfInput.get('omniscriptId')));
        } else if(methodName.equalsIgnoreCase('mergeAllElements')){
            
            List<String> listOfElementstoCopy = (List<String>)JSON.deserialize(JSON.serialize(mapOfInput.get('listOfElementstoCopy')), List<String>.class) ;
            String sourceOSId = (String)mapOfInput.get('sourceOSId');
            String destinationOSId = (String)mapOfInput.get('destinationOSId');
            Map<String,String> mapOfElementNameAndParentId =(Map<String,String>)JSON.deserialize(JSON.serialize(mapOfInput.get('mapOfElementNameAndParentId')), Map<String,String>.class) ;
           
            try{
                copyeleemntfromOmniscript(listOfElementstoCopy,sourceOSId,destinationOSId,mapOfElementNameAndParentId);
                return '{"success":"true"}';
            }catch(Exception ex){
                 return '{"success":"false","errorMessage":"'+ex.getMessage()+'"}';
            }
            
        }
        else if (methodName.equalsIgnoreCase('getExtnApexVersion')){
            ExtensionApexVersionDetail detail = new ExtensionApexVersionDetail();
            detail.Version = MS_Generic_DataUtilityHelper.CONSTANT_EXTENSION_APEX_VERSION;
            return System.JSON.serialize(detail);
        }
        
        return '';
    }
    
    /* Source omniscript */
     @AuraEnabled  
    public static   List<Omniscript> getAllOmniscriptComponents(String searchText,Boolean destinationQuery,Boolean elementTypeIP){
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
        if(destinationQuery){
            CONSTANT_QUERY_CONDITION += ' AND ( '+CONST_NS+'IsActive__c = false ) ';
        }
        
        CONSTANT_QUERY_CONDITION += ' AND ( '+CONST_NS+'IsProcedure__c ='+elementTypeIP+ ' ) '; 
        

       CONSTANT_DYNAMIC_QUERY =' Select ' + CONSTANT_FIELD_NAMES + 'from '+CONST_NS+'OmniScript__c'+ CONSTANT_QUERY_CONDITION +' order by Name';
     
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
        
         return  listElementsRetrieved;
    }
    
     /* Get  omniscript elements by omniscript Id  */
    @AuraEnabled
    public static Map<Id, OmniscriptElement>  getOmniscriptComponents(String omniscriptId){
     omniscriptId = String.escapeSingleQuotes(omniscriptId);

     String queryStr = 'SELECT Id, Name,'+CONST_NS+'Order__c, '+CONST_NS+'OmniScriptId__c, '+CONST_NS+'ParentElementId__c, '+CONST_NS+'Type__c,'+CONST_NS+'ParentElementType__c, '+CONST_NS+'ParentElementName__c from '+CONST_NS+'Element__c where '+CONST_NS+'OmniScriptId__c =:omniscriptId order by  '+CONST_NS+'Order__c ASC'; 
  
        Map<Id, OmniscriptElement> mapOfOmniscriptElement = new Map<Id, OmniscriptElement>();
       
        for(Sobject sObj : Database.query(queryStr)){
            OmniscriptElement omniElementObj = new OmniscriptElement();
            omniElementObj.Id       = (String) sObj.get('Id');
            omniElementObj.Name     = (String) sObj.get('Name');
            omniElementObj.ElementType   = (String) sObj.get(CONST_NS+ 'Type__c');
            omniElementObj.ParentElementId  = (String) sObj.get(CONST_NS+ 'ParentElementId__c'); 
            mapOfOmniscriptElement.put(omniElementObj.Id, omniElementObj);
        }
        
        return mapOfOmniscriptElement ;
    }
    
    
       /*****   Merge selected omniscript element ,Method  receives list of configuration from the UI to merge omniscript elements     *****/                                                     
    @AuraEnabled
    public static void copyeleemntfromOmniscript(List<String> listOfElementstoCopy,String sourceOSId, String destinationOSId, Map<String,String> mapOfElementNameAndParentId){
        
        
        if(mapOfElementNameAndParentId == null){
            mapOfElementNameAndParentId = new Map<String,String>();
        }
        
        List<Sobject> listOfElementtoinsert = new List<Sobject>();
        String sourceElementQuery ='SELECT Id, Name, '+CONST_NS+'OmniScriptId__c, '+CONST_NS+'ParentElementId__c, '+CONST_NS+'Type__c, '+CONST_NS+'Order__c, '+CONST_NS+'PropertySet__c, '+CONST_NS+'Level__c FROM '+CONST_NS+'Element__c   where '+CONST_NS+'OmniScriptId__c=:sourceOSId and Id in :listOfElementstoCopy';
        Map<String,Sobject> mapOfElementsToInsert = new   Map<String,Sobject>(Database.query(sourceElementQuery));
        
        String destElementQuery ='SELECT Id, Name FROM '+CONST_NS+'Element__c WHERE '+CONST_NS+'OmniScriptId__c =:destinationOSId';
        for(Sobject destElement : Database.query(destElementQuery) ){
            setOfNameOfDestinationOSElements.add((String)destElement.get('Name'));
        }

        insertOsElementWithDependency(mapOfElementsToInsert, new Set<String>(), new Map<String,Sobject>(), destinationOSId , mapOfElementNameAndParentId );
        
    }
    
    @AuraEnabled
    public static AdvanceTrackedResponse advanceTrackViewGetElementsJSON (String recordId , Boolean isOmniscript, String nodeType,List<String> listOfElementId ,Map<String,Boolean> options,List<String> selectedElementIds,List<String> searchOnlyElements ){
        List<Id> trackedElementsList = getDependencyElements(recordId,isOmniscript,nodeType,listOfElementId,options,selectedElementIds,searchOnlyElements);
        AdvanceTrackedResponse responseWrap = new AdvanceTrackedResponse();  
        responseWrap.listOfTrackedElementResponse = getElementListJSON(trackedElementsList, false);
        responseWrap.searchedInputNodeCombination = CONSTANT_INPUTNODE_COMBINATION;
        return responseWrap ;
    }
    
    
    @AuraEnabled
    public static Map<String, List<Id>>  checkAllDependencyElements(String recordId , Boolean isOmniscript, String nodeType,List<String> listOfElementId ,Map<String,Boolean> options,List<String> selectedElementIds,  List<String> searchOnlyElements){
        List<Id> trackedElementsList = getDependencyElements(recordId,isOmniscript,nodeType,listOfElementId,options,selectedElementIds,searchOnlyElements);
        Map<String, List<Id>> responseMap= new  Map<String, List<Id>>();
        responseMap.put('missingDependentElementList', trackedElementsList);
        responseMap.put('elementHasDependencyList', OUTPUT_LIST_OF_BIND_EXPRESSION_ELEMENTS);
        return responseMap;
    }
    
    @AuraEnabled
    public static List<Id> getDependencyElements(String recordId , Boolean isOmniscript, String nodeType,List<String> listOfElementId ,Map<String,Boolean> options,List<String> selectedElementIds, List<String> searchOnlyElements){
        
        
        Set<String> SetOfinputNode = new Set<String>();
        List<Id>  filteredDependecyElements = new  List<Id>();
        
        String regexBindExpression = '%(.*?)%';
        // String regexConditonExpression = '(?<=\\s*"\\s*show\\s*"\\s*:\\s*\\{\\s*.*"field":")([^"\',]*)(?<=".*)';
        String regexCondShortExp ='(?<="field":")([^"\',]*)(?<=".*)';
        
        for(SObject thisElement : database.query('SELECT Id, Name,'+CONST_NS+'PropertySet__c, '+CONST_NS+'Type__c from '+CONST_NS+'Element__c where Id IN :listOfElementId')){
            Boolean hasBindNode = false;
            
            Pattern patternBindNode = Pattern.compile(regexBindExpression); 
            Pattern patternConditionExpNodeShort = Pattern.compile(regexCondShortExp); 
            
            Matcher matcherObj = patternConditionExpNodeShort.matcher((String)thisElement.get(CONST_NS+'PropertySet__c')); 
            hasBindNode = extractInputNodes(SetOfinputNode, matcherObj,true);
            
            if(hasBindNode){
                OUTPUT_LIST_OF_BIND_EXPRESSION_ELEMENTS.add((String)thisElement.get('Id'));
            }
            
            Matcher  matcherObj1 = patternBindNode.matcher((String)thisElement.get(CONST_NS+'PropertySet__c')); 
            hasBindNode =  extractInputNodes(SetOfinputNode, matcherObj1,true); 
            
            if(hasBindNode){
                OUTPUT_LIST_OF_BIND_EXPRESSION_ELEMENTS.add((String)thisElement.get('Id'));
            }
            
        }
        
        if(SetOfinputNode.isEmpty()){
            return filteredDependecyElements;
        }
        
        
        List<MS_Generic_NodeTracker.JSONNodeReferrenceWrapper>  dependecyList  = MS_Generic_NodeTracker.trackSetValueMap(recordId,isOmniscript ,nodeType, searchOnlyElements, new List<String>(SetOfinputNode),options);
        
        List<Id> dependencyIdList = new  List<Id>();
        if(dependecyList != null && dependecyList.size()>0){
            for(MS_Generic_NodeTracker.JSONNodeReferrenceWrapper thisItem : dependecyList){
                if(!selectedElementIds.contains(thisItem.Id)){
                    filteredDependecyElements.add(thisItem.Id);
                }
                
            }
            
        }
        
        return filteredDependecyElements;
    }
       
    public static Boolean  extractInputNodes (Set<String> SetOfinputNode, Matcher matcherObj , Boolean includeAllCombination){
        Boolean hasBindNode = false;
        while (matcherObj.find()) {
            String bindNode = String.valueOf(matcherObj.group()).replaceAll('%','');
            CONSTANT_INPUTNODE_COMBINATION.add(bindNode);
            //  bindNode = bindNode.replace('|', '\\|');
            SetOfinputNode.add(bindNode);
            
            if(includeAllCombination && bindNode.containsAny(':')){
                
                List<String> innerNodeList = (List<String>)bindNode.split(':');
                bindNode = innerNodeList[0];
                SetOfinputNode.add(innerNodeList[innerNodeList.size()-1]);
                SetOfinputNode.add(bindNode);
            }
            
            hasBindNode =true;
        } 
        matcherObj = matcherObj.reset();
        return hasBindNode;
        
    }
    
    @AuraEnabled
    public static List<AdvanceTrackViewElement> getElementListJSON (List<String> listOfElementId ,Boolean checkBindExpression){
        if(listOfElementId == null || listOfElementId.isEmpty()){
            return new List<AdvanceTrackViewElement>()  ;
        }
        List<AdvanceTrackViewElement> responseList = new  List<AdvanceTrackViewElement>();
        
        String regexBindExpression = '%(.*?)%';
        String regexCondShortExp ='(?<="field":")([^"\',]*)(?<=".*)';
        
        for(Sobject thisElement : database.query('SELECT Id, Name,'+CONST_NS+'PropertySet__c, '+CONST_NS+'Type__c,'+CONST_NS+'Order__c from '+CONST_NS+'Element__c where id IN :listOfElementId')){
            
            AdvanceTrackViewElement thisAdvncElement = new AdvanceTrackViewElement();
            thisAdvncElement.Id =(String)thisElement.get('Id');
            thisAdvncElement.Name = (String)thisElement.get('Name');
            thisAdvncElement.elementType = (String)thisElement.get(CONST_NS+'Type__c');
            thisAdvncElement.sequenceOrder = (Double)thisElement.get(CONST_NS+'Order__c');
            if(checkBindExpression){
                thisAdvncElement.hasBindExpression = MS_Generic_DataUtilityHelper.isPatternMatchFound(regexBindExpression,(String)thisElement.get(CONST_NS+'PropertySet__c')) || MS_Generic_DataUtilityHelper.isPatternMatchFound(regexCondShortExp,(String)thisElement.get(CONST_NS+'PropertySet__c'));
                //ListOfbindExpressions
                if(thisAdvncElement.hasBindExpression){
                    Set<String> setOfBindExpression = new Set<String>();
                    Pattern patternBindNode = Pattern.compile(regexBindExpression); 
                    Pattern patternConditionExpNodeShort = Pattern.compile(regexCondShortExp); 
                    
                    Matcher matcherObj = patternConditionExpNodeShort.matcher((String)thisElement.get(CONST_NS+'PropertySet__c')); 
                    extractBindNodes(setOfBindExpression, matcherObj);
                    
                    Matcher  matcherObj1 = patternBindNode.matcher((String)thisElement.get(CONST_NS+'PropertySet__c')); 
                    extractBindNodes(setOfBindExpression, matcherObj1); 
                    thisAdvncElement.listOfbindExpressions = new List<String>(setOfBindExpression);
                }
                
                
            }
            
            thisAdvncElement.propertyJSON = (String)thisElement.get(CONST_NS+'PropertySet__c');
            responseList.add(thisAdvncElement);
        }
        return responseList;
    }
  
    
    
    /**  Re Used Methods  **/
    public static void insertOsElementWithDependency(Map<String,Sobject> mapOfElementsToInsert, Set<String> setOfInsertedElementsId, Map<String,Sobject> mapOfInsertedElements,String destinationOSId ,Map<String,String> mapOfElementNameAndParentId ){
       
        Map<String,Sobject> mapOfNewInsertedElements = new Map<String,Sobject>();
      
        for(Sobject elementToCopy :  mapOfElementsToInsert.values()){
            
            String elementParentId = (String)elementToCopy.get(CONST_NS+'ParentElementId__c') ;
            
            if(! mapOfInsertedElements.containsKey((String)elementToCopy.get('Name')) ){
                if(
                    elementParentId == null ||  mapOfElementNameAndParentId.containsKey((String)elementToCopy.get('Name')) ||
                    ( 
                        mapOfElementsToInsert.containsKey(elementParentId) 
                        &&  mapOfInsertedElements.containsKey((string)mapOfElementsToInsert.get(elementParentId).get('Name'))
                    )
                )
                    {
                        Sobject copiedElement  =   elementToCopy.clone(false, true, false, false);
                        
                        while(setOfNameOfDestinationOSElements.contains((String)copiedElement.get('Name')) || mapOfNewInsertedElements.containsKey((String)copiedElement.get('Name')))
                        {
                            String newElementName =  (String)copiedElement.get('Name') + '_Copy';
                        if(mapOfElementNameAndParentId.containsKey((String)copiedElement.get('Name'))){
                            mapOfElementNameAndParentId.put(newElementName ,mapOfElementNameAndParentId.get((String)copiedElement.get('Name'))); 
                            mapOfElementNameAndParentId.remove((String)copiedElement.get('Name'));
                        }
                        copiedElement.put('Name', newElementName); 
                        elementToCopy.put('Name', newElementName);
                        
                    }
                    
                    copiedElement.put(CONST_NS+'OmniScriptId__c' , destinationOSId);
                    
                    if(elementToCopy.get(CONST_NS+'ParentElementId__c') != null){
                        String parentId = mapOfElementNameAndParentId.containsKey((String)copiedElement.get('Name')) ? mapOfElementNameAndParentId.get((String)copiedElement.get('Name')) : mapOfInsertedElements.get((String)mapOfElementsToInsert.get((String)elementToCopy.get(CONST_NS+'ParentElementId__c')).get('Name')).Id ;
                        copiedElement.put(CONST_NS+'ParentElementId__c', parentId);
                        
                    }
                    
                    mapOfNewInsertedElements.put((String)copiedElement.get('Name'), copiedElement);
                }
            }
        }
        
        if(!mapOfNewInsertedElements.Keyset().isEmpty() && CONSTANT_MAXIMUM_DML_COUNT !=0){
            insert mapOfNewInsertedElements.values();
            mapOfInsertedElements.putAll(mapOfNewInsertedElements);
            --CONSTANT_MAXIMUM_DML_COUNT;
            
            
        }
        
        if(mapOfElementsToInsert.Keyset().size() != mapOfInsertedElements.Keyset().size()){
            insertOsElementWithDependency(mapOfElementsToInsert,setOfInsertedElementsId,mapOfInsertedElements,destinationOSId,mapOfElementNameAndParentId);  
        }
        
    }
     
    public static void  extractBindNodes (Set<String> SetOfinputNode, Matcher matcherObj ){
        
        while (matcherObj.find()) {
            String bindNode = String.valueOf(matcherObj.group()).replaceAll('%','');
            bindNode = bindNode.replace('|', '\\|');
            SetOfinputNode.add(bindNode);
        } 
        matcherObj = matcherObj.reset();
    }
    
    public class AdvanceTrackViewElement {
        @AuraEnabled public String  Id = '';
        @AuraEnabled public String  Name = '';
        @AuraEnabled public String  elementType = '';
        @AuraEnabled public Double  sequenceOrder = 0;
        @AuraEnabled public boolean hasBindExpression ;
        @AuraEnabled public String  propertyJSON = '';
        @AuraEnabled public List<String>  listOfbindExpressions = new List<String>();
        
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
      
    }
    
   
    
    public Class AdvanceTrackedResponse {
        @AuraEnabled public List<AdvanceTrackViewElement> listOfTrackedElementResponse = new List<AdvanceTrackViewElement>()  ;
        @AuraEnabled public List<String>  searchedInputNodeCombination;
    }
    
     public class ExtensionApexVersionDetail {
         @AuraEnabled public String  Version = '';
      @AuraEnabled public String  ClassName = 'MS_MergeElementsController';
        
    }
}
