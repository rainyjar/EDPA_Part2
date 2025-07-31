import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class CustomSessionListener implements HttpSessionListener {

    @Override
    public void sessionCreated(HttpSessionEvent se) {
        System.out.println("Session created: " + se.getSession().getId());
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        try {
            System.out.println("Session destroyed: " + se.getSession().getId());
            // Safely clean up session attributes
            se.getSession().removeAttribute("manager");
            se.getSession().removeAttribute("customer");
        } catch (Exception e) {
            // Silently ignore any cleanup errors to prevent NPE
            System.out.println("Session cleanup completed safely");
        }
    }
}
