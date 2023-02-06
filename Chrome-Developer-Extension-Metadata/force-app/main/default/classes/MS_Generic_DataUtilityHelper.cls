public without sharing class MS_Generic_DataUtilityHelper {
     
    public static String CONSTANT_EXTENSION_APEX_VERSION            = '1.1.1';

    public static List<String> CONSTANT_ALLOWED_NAMESPACE           =  new List<String> {'vlocity_cmt','vlocity_ins','vlocity_ps'};
    public static String CONST_NS =  getCurrentNameSpace(); 

    public static  String DEFAULT_JSON_REGEX_PATTERN                =  '(?<=\\s*"\\s*{rootNode}\\s*"\\s*:\\s*\\{\\s*.*)({inputList})(?<=.*)';  // new regex
    public static  String DEFAULT_INPUT_NODE_REGEX_PATTERN          =  '{inputNode}'; //new
    
    public static final String FIELD_NAME_OS_ELEMENT                =  'select Id , Name,'+CONST_NS+'SearchKey__c, '+CONST_NS+'Active__c, '+CONST_NS+'Order__c, '+CONST_NS+'OmniScriptId__c, '+CONST_NS+'PropertySet__c, '+CONST_NS+'Type__c ';
    public static final String RELATIONAL_FIELD_NAME_OS_OS_ELEMENT  =  ' , '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'Type__c,'+CONST_NS+'OmniScriptId__r.'+CONST_NS+'SubType__c , '+CONST_NS+'OmniScriptId__r.'+CONST_NS+'ProcedureKey__c ';
   
    public static  String REGEX_VIP_RESPONSE_ACTION_PATTERN_MAIN    =  '(\\s*"\\s*{rootNode}\\s*"\\s*:\\s*\\{\\s*.*({inputList}))';
    public static  String REGEX_VIP_RESPONSE_ACTION_PATTERN_INPUT   =  '"{inputNode}\\s*"\\s*:';
    
    public static  String REGEX_VIP_RESPONSE_NODE_PATTERN_MAIN      =  '(\\s*"\\s*{rootNode}\\s*"\\s*:\\s*\\s*.*(inputList))';
    public static  String REGEX_VIP_RESPONSE_NODE_PATTERN_INPUT     =  '"{inputNode}\\s*"\\s*';
    
    public static  String DEFAULT_MAIN_REGEX_PATTERN_ANY_NODE       =  '({inputList})';
    public static  String DEFAULT_INPUT_REGEX_PATTERN_ANY_NODE      =  '{inputNode}';
    
    public static  final String  LABEL_OS_ELEMENT                   =  'OmniScript';
    public static  final String  LABEL_VIP_ELEMENT                  =  'Integration Procedure Action'; 
    public static  final String  LABEL_SET_VALUE_ELEMENT            =  'Set Values';
    public static  final String  LABEL_TRACK_ANY_NODE               =  'TrackAnyNode';
    
   
    public static String   getCurrentNameSpace (){  
        String nameSpace='__';
        for(PackageLicense thisInstalledPkg : [SELECT Id, Status, NamespacePrefix FROM PackageLicense ){
            if(CONSTANT_ALLOWED_NAMESPACE.contains(thisInstalledPkg.NamespacePrefix )){
                nameSpace =thisInstalledPkg.NamespacePrefix+nameSpace;
                break;
            }
            
        }	
        return nameSpace;
    }
    
    public static String   generateRegexStringForInputNode(String inputNode,String actionType){
        String outputReg  ='';
       
        if(actionType == LABEL_TRACK_ANY_NODE){ 
            outputReg = inputNode;
        } else {
            
            if(inputNode.containsAny(':|')){
                inputNode = inputNode.replaceAll('(?<=.*)(\\|\\d+)(?<=.*)','\\[.*').replaceAll('(:)','{.*') ;  
                
                inputNode= inputNode.removeEnd('.*');
                //.replace('[','\\\\[');
            }
            outputReg = inputNode.replaceAll('(?:[^:\\|.*\\[{])+','"$0":');  
        }
        
        return outputReg;
    }
    
    public static string   getRegExpForInputNodes(String masterRegEx , String iterableRegExp, List<String> listOfInputNodes,String rootNodeName,String actionType){
        String constructedPattern = masterRegEx;
        constructedPattern  =  constructedPattern.replaceAll('\\{rootNode\\}',rootNodeName) ; 
        String constructedInputNodePattern ='';
        if(! listOfInputNodes.isEmpty()){
            for(String inputNode : listOfInputNodes){
                inputNode = generateRegexStringForInputNode(inputNode,actionType);
                
                constructedInputNodePattern += iterableRegExp.replaceAll('\\{inputNode\\}', inputNode)+'|';
            } 
            constructedInputNodePattern = constructedInputNodePattern.substringBeforeLast('|');
            
            constructedPattern = constructedPattern.replaceAll('\\{inputList\\}', constructedInputNodePattern);
        }
        constructedPattern = constructedPattern.replace('[','\\[').replace('{','\\{');
        constructedPattern = constructedPattern.replace('\\\\{','\\{');
        return constructedPattern;
        
    }
    
    public static Boolean  isPatternMatchFound (String regextStr, String strToCompare ){
        return System.Pattern.compile(regextStr).matcher(strToCompare).find();
    } 
    
    public static String   getRegexJSONReferenceNode ( String rootNode , List<String> listOfNodeToCheck ){
        String constructedPattern   = '(\\s*"\\s*{rootNode}\\s*"\\s*:\\s*\\{\\s*.*"field":({inputList}))';
        String inputNodeDefaultReg  = '"{inputNode}\\s*"\\s*';
        constructedPattern          =  constructedPattern.replaceAll('\\{rootNode\\}',rootNode) ; 
        String constructedInputNodePattern ='';
        if(String.isBlank(rootNode)){
            inputNodeDefaultReg = '(%{inputNode}%|%{inputNode}:.*%)';
            constructedPattern  = '{inputList}' ;
        }
     
        if(! listOfNodeToCheck.isEmpty()){
            for(String inputNode : listOfNodeToCheck){
                constructedInputNodePattern += inputNodeDefaultReg.replaceAll('\\{inputNode\\}', inputNode)+'|';
            } 
            constructedInputNodePattern = constructedInputNodePattern.substringBeforeLast('|');
            
            constructedPattern = constructedPattern.replaceAll('\\{inputList\\}', constructedInputNodePattern);
        }
        return constructedPattern;
    }
    
    public static Boolean  isOmniscriptElement (Sobject element){
        return String.valueOf(element.get(CONST_NS+'Type__c')).endsWithIgnoreCase(LABEL_OS_ELEMENT);
    }
    
    public static Boolean  isIntegrationProcedureElement (Sobject element){
        return String.valueOf(element.get(CONST_NS+'Type__c')).endsWithIgnoreCase(LABEL_VIP_ELEMENT);
    }
    
    public static Boolean  isSetValueElement (Sobject element){
        return String.valueOf(element.get(CONST_NS+'Type__c')).endsWithIgnoreCase(LABEL_SET_VALUE_ELEMENT);
    }
    
    public static String   getIntegrationProcedureName (String textToSerach , String regExp){
        System.Matcher matcherObj = System.Pattern.compile(regExp).matcher(textToSerach);
        String integrationProcedureKey = '';
        if(matcherObj.find()){
            integrationProcedureKey = matcherObj.group(1).split(':')[1].replaceAll('\\"','').trim();
        }
        return integrationProcedureKey;
    }
    
    public  Class OmniscriptElementWrapper {
        @auraEnabled public String elementName;
        @auraEnabled public Boolean ActiveStatus = true;
         
    }

    public  Class OmniscriptDefinationWrapper {
        @auraEnabled public String Name;
        @auraEnabled public String Id ='';
        @auraEnabled public String componentType ='';
        @auraEnabled public List<OmniscriptElementWrapper> elementList = new List<OmniscriptElementWrapper>();
    }
    
     
 
}
