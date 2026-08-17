import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class aerobic_guardApp extends Application.AppBase {
    var mField;

    function initialize() {
        AppBase.initialize();
        mField = null;
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Do not mutate properties while Garmin is constructing getSettingsView().
        // Profile/default initialization belongs to the data-field launch path.
        new AdvisoryDefaultsInitializer().initializeOnce();
        mField = new AerobicGuardField();
        return [ mField ];
    }

    function settingsChanged() as Void {
        if (mField != null) { mField.onSettingsChanged(); }
    }

    function onSettingsChanged() as Void { settingsChanged(); }

    function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [ buildSettingsMenu(), new SettingsMenuDelegate(:root, null) ];
    }

}

function getApp() as aerobic_guardApp {
    return Application.getApp() as aerobic_guardApp;
}
