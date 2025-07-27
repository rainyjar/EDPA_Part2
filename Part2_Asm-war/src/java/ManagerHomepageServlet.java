import java.io.IOException;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.Appointment;
import model.AppointmentFacade;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Manager;
import model.ManagerFacade;

@WebServlet(urlPatterns = {"/ManagerHomepageServlet", "/ManagerDashboardServlet", "/manager/dashboard"})
public class ManagerHomepageServlet extends HttpServlet {

    @EJB
    private AppointmentFacade appointmentFacade;

    @EJB
    private ManagerFacade managerFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Manager manager = (Manager) session.getAttribute("manager");

        if (manager == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        try {
            // Get all staff data
            List<Doctor> allDoctors = doctorFacade.findAll();
            List<CounterStaff> allStaff = counterStaffFacade.findAll();
            List<Manager> allManagers = managerFacade.findAll();
            List<Appointment> recentAppointments = appointmentFacade.findAll();
            
            // Get only recent appointments (limit to 10)
            if (recentAppointments != null && recentAppointments.size() > 10) {
                recentAppointments = recentAppointments.subList(0, 10);
            }

            // Sort doctors and staff by rating (highest first)
            if (allDoctors != null) {
                allDoctors.sort((d1, d2) -> {
                    Double rating1 = d1.getRating() != null ? d1.getRating() : 0.0;
                    Double rating2 = d2.getRating() != null ? d2.getRating() : 0.0;
                    return rating2.compareTo(rating1);
                });
            }

            if (allStaff != null) {
                allStaff.sort((s1, s2) -> {
                    Double rating1 = s1.getRating() != null ? s1.getRating() : 0.0;
                    Double rating2 = s2.getRating() != null ? s2.getRating() : 0.0;
                    return rating2.compareTo(rating1);
                });
            }

            // Calculate statistics
            int totalDoctors = allDoctors != null ? allDoctors.size() : 0;
            int totalStaff = allStaff != null ? allStaff.size() : 0;
            int totalManagers = allManagers != null ? allManagers.size() : 0;

            // Appointment statistics
            List<Appointment> allAppointments = appointmentFacade.findAll();
            int totalAppointments = allAppointments != null ? allAppointments.size() : 0;

            int pendingAppointments = 0;
            int completedAppointments = 0;

            if (allAppointments != null) {
                for (Appointment apt : allAppointments) {
                    if (apt.getStatus() != null && apt.getStatus().equalsIgnoreCase("pending")) {
                        pendingAppointments++;
                    }
                }
            }
            
            if (allAppointments != null) {
                for (Appointment apt : allAppointments) {
                    if (apt.getStatus() != null && apt.getStatus().equalsIgnoreCase("completed")) {
                        completedAppointments++;
                    }
                }
            }

            // Set request attributes
            request.setAttribute("doctorList", allDoctors);
            request.setAttribute("staffList", allStaff);
            request.setAttribute("managerList", allManagers);
            request.setAttribute("recentAppointments", recentAppointments);

            request.setAttribute("totalDoctors", totalDoctors);
            request.setAttribute("totalStaff", totalStaff);
            request.setAttribute("totalManagers", totalManagers);
            request.setAttribute("totalAppointments", totalAppointments);
            request.setAttribute("pendingAppointments", pendingAppointments);
            request.setAttribute("completedAppointments", completedAppointments);
            System.out.println("Manager logged in! Redirecting to manager homepage.");
            
            // Forward to JSP
            request.getRequestDispatcher("/manager/manager_homepage.jsp").forward(request, response);

        } catch (Exception e) {
            System.out.println("Error in ManagerHomepageServlet: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=dashboard_error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Manager Homepage Servlet - handles manager dashboard data loading";
    }

}
