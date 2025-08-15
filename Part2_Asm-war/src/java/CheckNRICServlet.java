import java.io.IOException;
import java.io.PrintWriter;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.*;

/**
 * Servlet that checks if an NRIC/IC is already in use by any user type
 * Used for client-side validation to prevent unique constraint violations
 */
@WebServlet(name = "CheckNRICServlet", urlPatterns = {"/CheckNRICServlet"})
public class CheckNRICServlet extends HttpServlet {
    
    @EJB
    private CustomerFacade customerFacade;
    
    @EJB
    private DoctorFacade doctorFacade;
    
    @EJB
    private CounterStaffFacade counterStaffFacade;
    
    @EJB
    private ManagerFacade managerFacade;
    
    /**
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Set response content type
        response.setContentType("text/plain");
        PrintWriter out = response.getWriter();
        
        try {
            // Get parameters
            String nric = request.getParameter("nric");
            String userType = request.getParameter("userType");
            int currentUserId = 0;
            
            // Get current user ID if editing (to exclude self from check)
            String userIdParam = request.getParameter("userId");
            if (userIdParam != null && !userIdParam.isEmpty()) {
                try {
                    currentUserId = Integer.parseInt(userIdParam);
                } catch (NumberFormatException e) {
                    // Ignore parsing errors, default to 0
                }
            }
            
            // Check if NRIC is available
            boolean isTaken = isNRICTaken(nric, userType, currentUserId);
            
            // Return result
            if (isTaken) {
                out.write("taken");
            } else {
                out.write("available");
            }
        } catch (Exception e) {
            // Log error
            getServletContext().log("Error checking NRIC availability", e);
            out.write("error");
        } finally {
            out.close();
        }
    }
    
    /**
     * @param nric The NRIC to check
     * @param userType The type of user being checked (customer, doctor, counterstaff, manager)
     * @param currentUserId The ID of the current user being edited (to exclude from check)
     * @return true if NRIC is already taken, false otherwise
     */
    private boolean isNRICTaken(String nric, String userType, int currentUserId) {
        if (nric == null || nric.isEmpty()) {
            return false;
        }
        
        // Check customers
        Customer customer = customerFacade.findByIc(nric);
        if (customer != null && !(userType != null && userType.equals("customer") && customer.getId() == currentUserId)) {
            return true;
        }
        
        // Check doctors
        Doctor doctor = doctorFacade.findByIc(nric);
        if (doctor != null && !(userType != null && userType.equals("doctor") && doctor.getId() == currentUserId)) {
            return true;
        }
        
        // Check counter staff
        CounterStaff staff = counterStaffFacade.findByIc(nric);
        if (staff != null && !(userType != null && userType.equals("counterstaff") && staff.getId() == currentUserId)) {
            return true;
        }
        
        // Check managers
        Manager manager = managerFacade.findByIc(nric);
        if (manager != null && !(userType != null && userType.equals("manager") && manager.getId() == currentUserId)) {
            return true;
        }
        
        return false;
    }
}

