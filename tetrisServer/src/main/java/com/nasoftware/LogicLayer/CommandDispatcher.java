package com.nasoftware.LogicLayer;
import org.json.JSONException;
import org.json.JSONObject;

public class CommandDispatcher {
    public void dispatchCommand(JSONObject header, CompletionHandler handler) throws JSONException {
        switch (header.getString("command")) {
            case "login":
                JSONObject jsonObject = new JSONObject();
                jsonObject.put("error", "0");
                handler.response(jsonObject);
                break;
        }
    }
}
