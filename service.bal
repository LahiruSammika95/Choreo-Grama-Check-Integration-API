import lahiru123/police_check_api_pv;
import chevon/gramacheck_id_api;
import areebniyas/addresscheck;
import wso2/choreo.sendsms;
import ballerina/http;

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

type apiResponse record {
    boolean valid;
    string msg;
};

service / on new http:Listener(9090) {

    resource function get validate(string nic, string address, string phone) returns json|error {

        /////////////////////////////////////ID VALIDATION API/////////////////////////////////////
        
        gramacheck_id_api:Client gramacheck_id_apiEndpoint = check new ({auth: {clientId:idApiClientID, clientSecret:idApiClientSecret}});
        IsValid getChecknicResponse = check gramacheck_id_apiEndpoint->getChecknic(nic);

        if getChecknicResponse.valid == false {
            apiResponse response = {
                valid: false,
                msg: "ID validation failed"
            };
            return response.toJson();
        }

        /////////////////////////////////////ADDRESS VALIDATION API/////////////////////////////////////
        addresscheck:Client addresscheckEndpoint = check new ({auth: {clientId: addressApiClientID, clientSecret:addressApiClientSecret}});
        json getCheckaddressResponse = check addresscheckEndpoint->getCheckaddress(nic, getChecknicResponse.address);
        if getCheckaddressResponse.valid == false {
            apiResponse response = {
                valid: false,
                msg: "Address validation failed"
            };
            return response.toJson();
        }
        /////////need to improve this section////////
        if getChecknicResponse.address.trim() != address.trim() {
            apiResponse response = {
                valid: false,
                msg: "Address validation failed"
            };
            return response.toJson();
        }

        /////////////////////////////////////POLICE VALIDATION API/////////////////////////////////////
        police_check_api_pv:Client police_check_api_pvEndpoint = check new ({auth: {clientId:policeApiClientID, clientSecret:policeApiClientSecret}});
        json getPersonCrimeRecordsResponse = check police_check_api_pvEndpoint->getPersoncrimerecords(nic);

        if getPersonCrimeRecordsResponse is json[] && getPersonCrimeRecordsResponse.length() > 0 {
            apiResponse response = {
                valid: false,
                msg: "Validation failed. Try again!!!"
            };
            return response.toJson();
        }
            else {
            apiResponse response = {
                valid: true,
                msg: "Congratulations!!! Validation successful."
            };

            sendsms:Client sendsmsEndpoint = check new ({});
            string _ = check sendsmsEndpoint->sendSms(phone, "Validation successful. Thank you.");
            return response.toJson();
        }

    }
}
