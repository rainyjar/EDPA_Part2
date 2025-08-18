import java.io.IOException;
import java.io.PrintWriter;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Customer;
import model.CustomerFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Manager;
import model.ManagerFacade;
import model.Appointment;
import model.AppointmentFacade;


/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/Login"})
public class Login extends HttpServlet {

    @EJB
    private ManagerFacade managerFacade;

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private CustomerFacade customerFacade;

    @EJB
    private AppointmentFacade appointmentFacade;

    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");

        // Handle logout
        String logout = request.getParameter("logout");
        String action = request.getParameter("action");

        if ((logout != null && logout.equals("true"))
                || (action != null && action.equals("logout"))) {
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.invalidate();
            }
            // Prevent caching
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setDateHeader("Expires", 0);

            response.sendRedirect("login.jsp");
            return;
        }

        try (PrintWriter out = response.getWriter()) {
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String role = request.getParameter("role");

            // Empty fields validation
            if (email == null || password == null || role == null
                    || email.isEmpty() || password.isEmpty() || role.isEmpty()) {
                request.setAttribute("error", "All fields are required.");
                request.getRequestDispatcher("login.jsp").forward(request, response);
                return;
            }
            try {
                Object user = null;

                switch (role.toLowerCase()) {
                    case "manager":
                        user = managerFacade.searchEmail(email);
                        break;
                    case "doctor":
                        user = doctorFacade.searchEmail(email);
                        break;
                    case "counter_staff":
                        user = counterStaffFacade.searchEmail(email);
                        break;
                    case "customer":
                        user = customerFacade.searchEmail(email);
                        break;
                }

                if (user == null) {
                    request.setAttribute("error", "No user found with this email.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }

                String userPassword = null;
                if (user instanceof Manager) {
                    userPassword = ((Manager) user).getPassword();
                } else if (user instanceof Doctor) {
                    userPassword = ((Doctor) user).getPassword();
                } else if (user instanceof CounterStaff) {
                    userPassword = ((CounterStaff) user).getPassword();
                } else if (user instanceof Customer) {
                    userPassword = ((Customer) user).getPassword();
                }

                if (!password.equals(userPassword)) {
                    request.setAttribute("error", "Incorrect password.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }

                HttpSession s = request.getSession();
                s.setAttribute("user", user);
                s.setAttribute("role", role);

                if (user != null) {
                    // Update overdue appointments for all user types
                    updateOverdueAppointments();
                }

                // Set the name based on role
                if (user instanceof Manager) {
                    s.setAttribute("manager", ((Manager) user));
                    response.sendRedirect("ManagerHomepageServlet");
                } else if (user instanceof Doctor) {
                    s.setAttribute("doctor", (Doctor) user);
                    response.sendRedirect("DoctorHomepageServlet?action=dashboard");
                } else if (user instanceof CounterStaff) {
                    s.setAttribute("staff", (CounterStaff) user);
                    response.sendRedirect("CounterStaffServletJam?action=dashboard");
                } else if (user instanceof Customer) {
                    s.setAttribute("customer", (Customer) user);
                    response.sendRedirect("CustomerHomepageServlet");
                    System.out.print(((Customer) user).getId());
                }

            } catch (Exception e) {
                request.setAttribute("error", "Login failed: " + e.getMessage());
                request.getRequestDispatcher("login.jsp").forward(request, response);
            }
        }
    }

        private void updateOverdueAppointments() {
        try {
            System.out.println("=== LOGIN: UPDATING OVERDUE APPOINTMENTS ===");
    
            // Get current date/time
            Calendar currentCal = Calendar.getInstance();
            Date currentDateTime = currentCal.getTime();
            
            // Create a calendar for "yesterday" to establish the grace period
            Calendar yesterdayCal = Calendar.getInstance();
            yesterdayCal.add(Calendar.DATE, -1);
            yesterdayCal.set(Calendar.HOUR_OF_DAY, 23);
            yesterdayCal.set(Calendar.MINUTE, 59);
            yesterdayCal.set(Calendar.SECOND, 59);
            Date yesterdayEndOfDay = yesterdayCal.getTime();
            
            List<Appointment> allAppointments = appointmentFacade.findAll();
    
            if (allAppointments == null || allAppointments.isEmpty()) {
                System.out.println("No appointments found in database");
                return;
            }
    
            int updatedAppointments = 0;
    
            for (Appointment appointment : allAppointments) {
                try {
                    if (appointment == null) {
                        continue;
                    }
    
                    String currentStatus = appointment.getStatus();
                    if (currentStatus == null
                            || !(currentStatus.equals("pending") || currentStatus.equals("approved") || currentStatus.equals("reschedule"))) {
                        continue;
                    }
    
                    if (appointment.getAppointmentDate() == null || appointment.getAppointmentTime() == null) {
                        continue;
                    }
    
                    // Combine appointment date and time
                    Calendar appointmentCalendar = Calendar.getInstance();
                    appointmentCalendar.setTime(appointment.getAppointmentDate());
    
                    Calendar timeCalendar = Calendar.getInstance();
                    timeCalendar.setTime(appointment.getAppointmentTime());
    
                    appointmentCalendar.set(Calendar.HOUR_OF_DAY, timeCalendar.get(Calendar.HOUR_OF_DAY));
                    appointmentCalendar.set(Calendar.MINUTE, timeCalendar.get(Calendar.MINUTE));
                    appointmentCalendar.set(Calendar.SECOND, 0);
                    appointmentCalendar.set(Calendar.MILLISECOND, 0);
    
                    Date appointmentDateTime = appointmentCalendar.getTime();
    
                    // Change: Only mark as overdue if the appointment was from a previous day
                    // (Before end of yesterday)
                    if (appointmentDateTime.before(yesterdayEndOfDay)) {
                        appointment.setStatus("overdue");
                        appointmentFacade.edit(appointment);
                        updatedAppointments++;
    
                        System.out.println("✓ Updated appointment ID " + appointment.getId() + " to overdue");
                    }
    
                } catch (Exception e) {
                    System.out.println("Error processing appointment: " + e.getMessage());
                }
            }
    
            System.out.println("Login overdue update: " + updatedAppointments + " appointments updated");
            System.out.println("=== LOGIN OVERDUE UPDATE COMPLETED ===");
    
        } catch (Exception e) {
            System.out.println("ERROR in login overdue update: " + e.getMessage());
            // Don't throw - login should still work even if this fails
        }
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>
}
