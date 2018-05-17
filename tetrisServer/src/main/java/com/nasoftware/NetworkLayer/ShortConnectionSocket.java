package com.nasoftware.NetworkLayer;
import com.nasoftware.LogicLayer.CommandDispatcher;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.*;
import java.net.Socket;

public class ShortConnectionSocket extends Thread {
    private Socket socket;


    ShortConnectionSocket(Socket socket) {
        this.socket = socket;
    }

    @Override
    public void run() {
        try {
            DataInputStream in = new DataInputStream(socket.getInputStream());
            String requestHeader = in.readUTF();
            JSONObject header = new JSONObject(requestHeader);
            CommandDispatcher commandDispatcher = new CommandDispatcher();
            commandDispatcher.dispatchCommand(header, response -> {
                response(response);
            });
        } catch (IOException e) {
            e.printStackTrace();
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void response(JSONObject content) {
        PrintWriter pw = null;
        try {
            pw = new PrintWriter(socket.getOutputStream());
        } catch (IOException e) {
            e.printStackTrace();
        }
        try {
            pw.println(content.toString());
            pw.flush();
            socket.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}