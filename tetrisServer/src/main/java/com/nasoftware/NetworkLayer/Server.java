package com.nasoftware.NetworkLayer;
import java.io.*;
import java.net.Socket;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class Server extends Thread {
    private final Socket server;
    private Lock lock = new ReentrantLock();
    private String account = "";
    private Integer serverID;

    static public Server create(Socket server, int id) {
        Server newServer = new Server(server);
        newServer.serverID = id;
        newServer.start();
        return newServer;
    }

    public Server(Socket server) {
        this.server = server;
    }

    public void run() {
        try {
            PrintWriter writer = new PrintWriter(server.getOutputStream());
            while (true) {
                try {
                    sleep(50);
                    writer.println("你好吗？  sdfsdf。？/.");
                    writer.flush();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            /*
            DataInputStream in = new DataInputStream(server.getInputStream());
            while (true) {
                String buffer = in.readUTF();
                System.out.println(buffer);
            }
            */
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private String getString(char content[]) {
        StringBuilder stringBuilder = new StringBuilder();
        int length = content.length;
        for(int i=0; i<length; ++i) {
            if(content[i] == 0)
                break;
            stringBuilder.append(content[i]);
        }
        return stringBuilder.toString();
    }

    public void sendPack(String pack) {
        try {
            lock.lock();
            DataOutputStream out = new DataOutputStream(server.getOutputStream());
            out.writeUTF(pack);
            lock.unlock();
        } catch (IOException e) {
            return;
        }
    }

}
