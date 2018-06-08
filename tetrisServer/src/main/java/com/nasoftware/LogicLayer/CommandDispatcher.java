package com.nasoftware.LogicLayer;
import org.json.JSONException;
import org.json.JSONObject;

public class CommandDispatcher {
    public void dispatchCommand(JSONObject header, CompletionHandler handler) throws JSONException {
        if(header.getString("requestType").equals("CGI")) {
            switch (header.getString("command")) {
                case "login":
                    JSONObject jsonObject = new JSONObject();
                    jsonObject.put("error", "0");
                    jsonObject.put("type", "CGI");
                    jsonObject.put("requestID", header.getString("requestID"));
                    handler.response(jsonObject);
                    break;
            }
        }

    }
}
