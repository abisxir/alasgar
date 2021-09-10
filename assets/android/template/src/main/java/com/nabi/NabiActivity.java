package com.alasgar;
import org.libsdl.app.SDLActivity;

public class AlasgarActivity extends SDLActivity {

	@Override
	// For disabling include of dynamic SDL library file.
	// It's statically linked now.
	protected String[] getLibraries() {
        return new String[] {"hidapi", "main"};
    }
}
