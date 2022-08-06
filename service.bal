import chevon/gramacheck_id_api;
import areebniyas/addresscheck;
import lahiru123/police_check_v2;
import wso2/choreo.sendsms;
import ballerina/http;

configurable string idapiEndpointClientID = ?;
configurable string idapiEndpointClientSecret = ?;
configurable string police_check_apiEndpointClientID = ?;
configurable string police_check_apiEndpointClientSecret = ?;

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
        gramacheck_id_api:Client gramacheck_id_apiEndpoint = check new ({auth: {clientId: "dN9DM0a01Ybjorj3g_3osbtbGpQa", clientSecret: "ABunqnutPH931_dpfVOs596I11Ma"}});
        IsValid getChecknicResponse = check gramacheck_id_apiEndpoint->getChecknic(nic);

        if getChecknicResponse.valid == false {
            apiResponse response = {
                valid: false,
                msg: "ID validation failed"
            };
            return response.toJson();
        }

        /////////////////////////////////////ADDRESS VALIDATION API/////////////////////////////////////
        addresscheck:Client addresscheckEndpoint = check new ({auth: {clientId: "NeTXguM6mS9CW1x_PqaSRDuAWJga", clientSecret: "XMC3UoNTS4fEC20XY7lZum4fKOoa"}});
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
        police_check_v2:Client police_check_v2Endpoint = check new ({auth: {clientId: "S1ChxLJNfAXY34JvT2IH8TcGhOAa", clientSecret: "Q2pUhOJMf0YS8RUiRXYrBxi8Pk8a"}});
        json getPersonCrimeRecordsResponse = check police_check_v2Endpoint->getPersoncrimerecords(nic);

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
