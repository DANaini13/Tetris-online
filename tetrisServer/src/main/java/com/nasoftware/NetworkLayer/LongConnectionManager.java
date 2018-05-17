package com.nasoftware.NetworkLayer;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

public class LongConnectionManager extends Thread {
    private static LongConnectionManager serverManager = null;

    public static synchronized LongConnectionManager getServerManager(int port) {
        if(serverManager == null) {
            serverManager = new LongConnectionManager(port);
            serverManager.start();
        }
        return serverManager;
    }

    private final int port;
    private Integer serverID = 0;

    LongConnectionManager(int port) {
        this.port = port;
    }

    public void run() {
        try {
            ServerSocket serverSocket = new ServerSocket(port);
            while (true) {
                Socket server = serverSocket.accept();
                LongConnectionSocket newLongConnectionSocket = LongConnectionSocket.create(server, serverID);
                ++serverID;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
