package com.nasoftware.NetworkLayer;

import org.json.JSONObject;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class ServerManager extends Thread {
    private static ServerManager serverManager = null;

    public static synchronized ServerManager getServerManager(int port) {
        if(serverManager == null) {
            serverManager = new ServerManager(port);
            serverManager.start();
        }
        return serverManager;
    }

    private final int port;
    private HashMap<String, Server> serverMap;
    private HashMap<String, Server> accountMap;
    private Lock mapLock = new ReentrantLock();
    private Lock accountLock = new ReentrantLock();
    private Integer serverID = 0;

    ServerManager(int port) {
        this.port = port;
        this.serverMap = new HashMap<>();
        this.accountMap = new HashMap<>();
    }

    public void addToAccountMap(String account, Server server) {
        accountLock.lock();
        this.accountMap.put(account, server);
        accountLock.unlock();
    }

    public void run() {
        try {
            ServerSocket serverSocket = new ServerSocket(port);
            while (true) {
                Socket server = serverSocket.accept();
                Server newServer = Server.create(server, serverID);
                this.serverMap.put(serverID.toString(), newServer);
                ++serverID;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void sendNotifications(JSONObject message) {
        accountLock.lock();
        Iterator it = accountMap.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry entry = (Map.Entry)it.next();
            Server server = (Server)entry.getValue();
            server.sendPack(message.toString());
        }
        accountLock.unlock();
    }

    public void pushMessageTo(String account, JSONObject message) {
        accountLock.lock();
        Server server = accountMap.get(account);
        if(server == null) {
            accountLock.unlock();
            return;
        }
        server.sendPack(message.toString());
        accountLock.unlock();
    }

    public void removeServer(Integer serverID, String account) {
        mapLock.lock();
        this.serverMap.remove(serverID.toString());
        mapLock.unlock();
        accountLock.lock();
        this.accountMap.remove(account);
        accountLock.unlock();
    }
}
