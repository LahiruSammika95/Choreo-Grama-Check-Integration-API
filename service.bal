import lahiru123/police_check_api_pv;
import chevon/gramacheck_id_api;
import areebniyas/addresscheck;
import wso2/choreo.sendsms;
import ballerina/http;
import ballerinax/slack;
configurable string idApiClientID = ?;
configurable string idApiClientSecret = ?;
configurable string addressApiClientID = ?;
configurable string addressApiClientSecret = ?;
configurable string policeApiClientID = ?;
configurable string policeApiClientSecret = ?;

type IsValid record {
    boolean valid;
    string nic;
    string address;
};

type ApiResponse record {
    boolean valid;
    string msg;
};
function postMsgOnSlack(string nic, string address,string phone,string validationErr) returns string|error {

            string slackMsg="Issue: The "+validationErr+". (NIC: "+nic+"  Contact  No: "+phone+" Address: "+address+")";
            slack:Client slackEndpoint = check new ({auth: {token: "xoxb-3910737758228-3893774745143-Q3pRDjORWTi6gdZGaJ5pfwV7"}});
            slack:Message msg={channelName: "general", text:slackMsg};
            string msgResponse = check slackEndpoint->postMessage(msg);
            return msgResponse;
            

}
service / on new http:Listener(9090) {

    resource function get validate(string nic, string address, string phone) returns json|error {

        string reqNic=nic.trim();
        string reqAddress=address.trim();
        string reqPhone=phone.trim();
        
        /////////////////////////////////////ID VALIDATION API/////////////////////////////////////
        
        gramacheck_id_api:Client gramacheck_id_apiEndpoint = check new ({auth: {clientId:idApiClientID, clientSecret:idApiClientSecret}});
        IsValid getChecknicResponse = check gramacheck_id_apiEndpoint->getChecknic(reqNic);

        if getChecknicResponse.valid == false {
            ApiResponse response = {
                valid: false,
                msg: "ID validation failed"
            };
            
              future<string|error> _=start postMsgOnSlack(reqNic,reqAddress,reqPhone,"ID validation failed");
   
            // string _=check postMsgOnSlack(reqNic,reqAddress,reqPhone,"ID validation failed");
  
            return response.toJson();
        }

        /////////////////////////////////////ADDRESS VALIDATION API/////////////////////////////////////
        addresscheck:Client addresscheckEndpoint = check new ({auth: {clientId: addressApiClientID, clientSecret:addressApiClientSecret}});
        json getCheckaddressResponse = check addresscheckEndpoint->getCheckaddress(reqNic, getChecknicResponse.address);
        if((getCheckaddressResponse.valid == false)||( getChecknicResponse.address.trim() != reqAddress)) {
            ApiResponse response = {
                valid: false,
                msg: "Address validation failed"
            };
            future<string|error> _=start postMsgOnSlack(reqNic,reqAddress,reqPhone,"Address validation failed");
            return response.toJson();
        }

        /////////////////////////////////////POLICE VALIDATION API/////////////////////////////////////
        police_check_api_pv:Client police_check_api_pvEndpoint = check new ({auth: {clientId:policeApiClientID, clientSecret:policeApiClientSecret}});
        json getPersonCrimeRecordsResponse = check police_check_api_pvEndpoint->getPersoncrimerecords(reqNic);

        if getPersonCrimeRecordsResponse is json[] && getPersonCrimeRecordsResponse.length() > 0 {
            ApiResponse response = {
                valid: false,
                msg: "Validation failed. Try again!!!"
            };
            future<string|error> _=start postMsgOnSlack(reqNic,reqAddress,reqPhone,"Validation failed");
            return response.toJson();
        }
            else {
            ApiResponse response = {
                valid: true,
                msg: "Congratulations!!! Validation successful."
            };

            sendsms:Client sendsmsEndpoint = check new ({});
            future<string|error> _ =start sendsmsEndpoint->sendSms(reqPhone, "Validation successful. Thank you.");
            return response.toJson();
        }

    }
}
