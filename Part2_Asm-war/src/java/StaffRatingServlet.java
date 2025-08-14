
import java.io.IOException;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.*;

/**
 * StaffRatingServlet handles staff rating operations for the APU Medical Center
 * Following JSP-EJB-Servlet architecture pattern similar to ManagerServlet
 *
 * @author chris
 */
@WebServlet(name = "StaffRatingServlet", urlPatterns = {"/StaffRatingServlet"})
public class StaffRatingServlet extends HttpServlet {

    @EJB
    private FeedbackFacade feedbackFacade;

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isManagerLoggedIn(request, response)) {
            return;
        }

        if (doctorFacade == null || counterStaffFacade == null || feedbackFacade == null) {
            throw new ServletException("One or more EJBs not injected properly.");
        }

        String action = request.getParameter("action");

        try {
            if ("viewFeedbackDetails".equals(action)) {
                handleFeedbackDetails(request, response);
            } else {
                // Default action - load all data for staff rating page
                handleViewStaffRating(request, response);
            }
        } catch (Exception e) {
            System.out.println("Error in StaffRatingServlet: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/manager/staff_rating.jsp?error=system_error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }

    /**
     * Handle viewing staff rating data - similar to ManagerServlet's viewAll
     * action
     */
    private void handleViewStaffRating(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Load all data from EJB facades (similar to ManagerServlet pattern)
        List<Doctor> doctorList = doctorFacade.findAll();
        List<CounterStaff> staffList = counterStaffFacade.findAll();
        List<Feedback> feedbackList = feedbackFacade.findAll();

        // Debug output
        System.out.println("StaffRatingServlet: Loading staff rating data...");
        System.out.println("Doctors found: " + (doctorList != null ? doctorList.size() : "null"));
        System.out.println("Counter Staff found: " + (staffList != null ? staffList.size() : "null"));
        System.out.println("Feedbacks found: " + (feedbackList != null ? feedbackList.size() : "null"));

        // Sort by ID for consistent ordering (like ManagerServlet)
        if (doctorList != null) {
            doctorList.sort((d1, d2) -> Integer.compare(d1.getId(), d2.getId()));
        }

        if (staffList != null) {
            staffList.sort((s1, s2) -> Integer.compare(s1.getId(), s2.getId()));
        }

        // Set attributes for JSP (JSP will handle filtering, sorting, and rating calculations)
        request.setAttribute("doctorList", doctorList);
        request.setAttribute("staffList", staffList);
        request.setAttribute("feedbackList", feedbackList);

        System.out.println("StaffRatingServlet: Forwarding to staff_rating.jsp");
        request.getRequestDispatcher("/manager/staff_rating.jsp").forward(request, response);
    }

    /**
     * Handle feedback details for individual staff
     */
    private void handleFeedbackDetails(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String staffType = request.getParameter("type");
        String staffIdParam = request.getParameter("id");
        String staffName = request.getParameter("name");

        System.out.println("StaffRatingServlet: handleFeedbackDetails called");
        System.out.println("Staff Type: " + staffType);
        System.out.println("Staff ID: " + staffIdParam);
        System.out.println("Staff Name: " + staffName);

        if (staffType == null || staffIdParam == null || staffName == null) {
            System.out.println("ERROR: Missing required parameters");
            response.sendRedirect(request.getContextPath() + "/StaffRatingServlet");
            return;
        }

        try {
            int staffId = Integer.parseInt(staffIdParam);

            // Get the actual staff object to access getRating() method
            Object staffObject = null;
            if ("doctor".equals(staffType)) {
                staffObject = doctorFacade.find(staffId);
            } else if ("staff".equals(staffType)) {
                staffObject = counterStaffFacade.find(staffId);
            }

            // Load all feedbacks (JSP will filter for specific staff)
            List<Feedback> feedbackList = feedbackFacade.findAll();
            System.out.println("Total feedbacks found: " + (feedbackList != null ? feedbackList.size() : "null"));

            // Set attributes for feedback details page
            request.setAttribute("staffType", staffType);
            request.setAttribute("staffId", staffId);
            request.setAttribute("staffName", staffName);
            request.setAttribute("staffObject", staffObject);
            request.setAttribute("feedbackList", feedbackList);

            System.out.println("Forwarding to staff_feedback_details.jsp");
            // Forward to feedback details page
            request.getRequestDispatcher("/manager/staff_feedback_details.jsp").forward(request, response);

        } catch (NumberFormatException e) {
            System.out.println("Invalid staff ID: " + staffIdParam);
            response.sendRedirect(request.getContextPath() + "/StaffRatingServlet?error=invalid_id");
        } catch (Exception e) {
            System.out.println("ERROR in handleFeedbackDetails: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/StaffRatingServlet?error=system_error");
        }
    }

    /**
     * Check if manager is logged in (similar to ManagerServlet)
     */
    private boolean isManagerLoggedIn(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("manager") == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return false;
            }
            return true;
        } catch (IllegalStateException e) {
            // Already committed response, can't redirect
            System.out.println("Warning: Response already committed. Skipping redirect.");
            return false;
        }
    }

    @Override
    public String getServletInfo() {
        return "StaffRatingServlet - Handles staff rating operations following JSP-EJB-Servlet architecture";
    }
}
