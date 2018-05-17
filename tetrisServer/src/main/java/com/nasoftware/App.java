package com.nasoftware;

import com.nasoftware.NetworkLayer.LongConnectionManager;
import com.nasoftware.NetworkLayer.ShortConnectionManager;

/**
 * Hello world!
 *
 */
public class App 
{
    public static void main( String[] args )
    {
        ShortConnectionManager.getServerManager(2023);
        LongConnectionManager.getServerManager(2022);
    }
}
