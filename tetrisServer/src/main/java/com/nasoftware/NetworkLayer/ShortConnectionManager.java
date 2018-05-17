package com.nasoftware.NetworkLayer;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

public class ShortConnectionManager extends Thread {
    private static ShortConnectionManager shortConnectionManager = null;

    public static synchronized ShortConnectionManager getServerManager(int port) {
        if(shortConnectionManager == null) {
            shortConnectionManager = new ShortConnectionManager(port);
            shortConnectionManager.start();
        }
        return shortConnectionManager;
    }

    private final int port;

    ShortConnectionManager(int port) {
        this.port = port;
    }

    public void run() {
        try {
            ServerSocket serverSocket = new ServerSocket(port);
            while (true) {
                Socket server = serverSocket.accept();
                ShortConnectionSocket socket = new ShortConnectionSocket(server);
                socket.start();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
