import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.*;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.*;

/**
 * ReportServlet handles the generation of real-time analytics and reports for the manager dashboard
 */
@WebServlet(name = "ReportServlet", urlPatterns = {"/ReportServlet"})
public class ReportServlet extends HttpServlet {

    @EJB
    private model.AppointmentFacade appointmentFacade;
    
    @EJB
    private model.DoctorFacade doctorFacade;
    
    @EJB
    private model.ManagerFacade managerFacade;
    
    @EJB
    private model.CounterStaffFacade counterStaffFacade;
    
    @EJB
    private model.CustomerFacade customerFacade;
    
    @EJB
    private model.TreatmentFacade treatmentFacade;
    
    @EJB
    private model.FeedbackFacade feedbackFacade;
    
    @EJB
    private model.PaymentFacade paymentFacade;

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
     * methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession session = request.getSession();
        Manager loggedInManager = (Manager) session.getAttribute("manager");
        
        if (loggedInManager == null) {
            // Return error if not logged in as manager
            response.getWriter().write("{\"status\": \"error\", \"message\": \"Authentication required\"}");
            return;
        }
        
        String action = request.getParameter("action");
        
        try (PrintWriter out = response.getWriter()) {
            if (action == null) {
                action = "dashboard_data"; // Default action
            }
            
            switch (action) {
                case "dashboard_data":
                    getDashboardData(out);
                    break;
                case "revenue_chart":
                    getRevenueChartData(out, request.getParameter("timeframe"));
                    break;
                case "appointment_chart":
                    getAppointmentChartData(out, request.getParameter("timeframe"));
                    break;
                case "staff_performance":
                    getStaffPerformanceData(out);
                    break;
                case "demographics":
                    getDemographicsData(out, request.getParameter("type"));
                    break;
                default:
                    out.print("{\"status\": \"error\", \"message\": \"Unknown action\"}");
            }
        } catch (Exception e) {
            // Log the error
            System.err.println("Error in ReportServlet: " + e.getMessage());
            e.printStackTrace();
            
            // Return error response
            response.getWriter().write("{\"status\": \"error\", \"message\": \"An error occurred: " + e.getMessage().replace("\"", "\\\"") + "\"}");
        }
    }
    
    /**
     * Generate complete dashboard data
     */
    private void getDashboardData(PrintWriter out) {
        // Get KPI data
        double totalRevenue = calculateTotalRevenue();
        int totalAppointments = appointmentFacade.count();
        int totalStaff = getTotalStaffCount();
        double avgRating = calculateAverageRating();
        
        // Build JSON manually
        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"totalRevenue\": \"").append(String.format("%.2f", totalRevenue)).append("\",");
        json.append("\"totalAppointments\": ").append(totalAppointments).append(",");
        json.append("\"totalStaff\": ").append(totalStaff).append(",");
        json.append("\"avgRating\": ").append(String.format("%.1f", avgRating)).append(",");
        json.append("\"topDoctors\": [],");
        json.append("\"mostBooked\": []");
        json.append("}");
        
        out.print(json.toString());
    }
    
    /**
     * Generate revenue chart data
     */
    private void getRevenueChartData(PrintWriter out, String timeframe) {
        // Simple revenue chart with mock data for now
        out.print("{\"labels\": [\"Jan\", \"Feb\", \"Mar\", \"Apr\", \"May\", \"Jun\"], \"data\": [1000, 1200, 1100, 1300, 1250, 1400]}");
    }
    
    /**
     * Generate appointment chart data
     */
    private void getAppointmentChartData(PrintWriter out, String timeframe) {
        // Simple appointment chart with mock data for now
        out.print("{\"labels\": [\"Mon\", \"Tue\", \"Wed\", \"Thu\", \"Fri\", \"Sat\", \"Sun\"], \"data\": [5, 8, 6, 10, 7, 4, 3]}");
    }
    
    /**
     * Generate staff performance chart data
     */
    private void getStaffPerformanceData(PrintWriter out) {
        // Simple staff performance chart with mock data for now
        out.print("{\"labels\": [\"Dr. Smith\", \"Dr. Johnson\", \"Dr. Brown\"], \"data\": [8.5, 9.0, 7.8], \"backgroundColor\": [\"#ff6b6b\", \"#4ecdc4\", \"#45b7d1\"]}");
    }
    
    /**
     * Generate demographics chart data
     */
    private void getDemographicsData(PrintWriter out, String type) {
        // Simple demographics chart with mock data for now
        out.print("{\"labels\": [\"Male\", \"Female\"], \"data\": [12, 8], \"backgroundColor\": [\"#667eea\", \"#764ba2\"]}");
    }
    
    // ======== Helper Methods ========
    
    private double calculateTotalRevenue() {
        double totalRevenue = 0;
        
        try {
            // Get all payments directly from PaymentFacade
            List<Payment> payments = paymentFacade.findAll();
            
            // Sum up the revenues from completed/paid payments
            for (Payment payment : payments) {
                // Only count payments that are completed/paid
                if ("completed".equalsIgnoreCase(payment.getStatus()) || 
                    "paid".equalsIgnoreCase(payment.getStatus())) {
                    totalRevenue += payment.getAmount();
                }
            }
        } catch (Exception e) {
            System.err.println("Error calculating total revenue: " + e.getMessage());
        }
        
        return totalRevenue;
    }
    
    private int getTotalStaffCount() {
        try {
            // Sum of all staff members
            return doctorFacade.count() + counterStaffFacade.count() + managerFacade.count();
        } catch (Exception e) {
            System.err.println("Error calculating total staff count: " + e.getMessage());
            return 0;
        }
    }
    
    private double calculateAverageRating() {
        try {
            // Get all doctors and counter staff
            List<Doctor> doctors = doctorFacade.findAll();
            List<CounterStaff> counterStaffs = counterStaffFacade.findAll();
            
            double totalRating = 0;
            int count = 0;
            
            // Add doctor ratings
            for (Doctor doctor : doctors) {
                Double rating = doctor.getRating();
                if (rating != null) {
                    totalRating += rating;
                    count++;
                }
            }
            
            // Add counter staff ratings
            for (CounterStaff staff : counterStaffs) {
                Double rating = staff.getRating();
                if (rating != null) {
                    totalRating += rating;
                    count++;
                }
            }
            
            return count > 0 ? (totalRating / count) : 0.0;
        } catch (Exception e) {
            System.err.println("Error calculating average rating: " + e.getMessage());
            return 0.0;
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
        return "Report servlet for dashboard analytics";
    }// </editor-fold>

}
