package com.nasoftware.NetworkLayer;
import com.nasoftware.LogicLayer.CommandDispatcher;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.*;
import java.net.Socket;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class LongConnectionSocket extends Thread {
    private final Socket server;
    private Lock lock = new ReentrantLock();

    static public LongConnectionSocket create(Socket server, int id) {
        LongConnectionSocket newLongConnectionSocket = new LongConnectionSocket(server);
        newLongConnectionSocket.start();
        return newLongConnectionSocket;
    }

    public LongConnectionSocket(Socket server) {
        this.server = server;
    }

    public void run() {
        try {
            DataInputStream in = new DataInputStream(server.getInputStream());
            while (true) {
                String buffer = in.readUTF();
                System.out.println(buffer);
                JSONObject header = new JSONObject(buffer);
                CommandDispatcher commandDispatcher = new CommandDispatcher();
                commandDispatcher.dispatchCommand(header, response -> {

                });
            }
        } catch (IOException e) {
            return;
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void sendPack(String pack) {
        try {
            lock.lock();
            PrintWriter writer = new PrintWriter(server.getOutputStream());
            writer.print(pack);
            writer.flush();
            lock.unlock();
        } catch (IOException e) {
            return;
        }
    }

}
