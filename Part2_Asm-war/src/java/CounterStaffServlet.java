import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.ArrayList;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Customer;
import model.CustomerFacade;
import model.Appointment;
import model.AppointmentFacade;
import model.Payment;
import model.PaymentFacade;
import model.Feedback;
import model.FeedbackFacade;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/CounterStaffServlet"})
@MultipartConfig

public class CounterStaffServlet extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;
    @EJB
    private CustomerFacade customerFacade;
    @EJB
    private AppointmentFacade appointmentFacade;
    @EJB
    private PaymentFacade paymentFacade;
    @EJB
    private FeedbackFacade feedbackFacade;

    //    register new counter staff (not yet validate)
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html");
        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counter_staff = counterStaffFacade.find(id);
            if (counter_staff != null) {
                counterStaffFacade.remove(counter_staff);
            }
            response.sendRedirect("CounterStaffServlet"); // reload list
        } else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counter_staff = counterStaffFacade.find(id);

            if (counter_staff != null) {
                counter_staff.setName(request.getParameter("name"));
                counter_staff.setEmail(request.getParameter("email"));
                counter_staff.setPassword(request.getParameter("password"));
                counter_staff.setPhone(request.getParameter("phone"));
                counter_staff.setGender(request.getParameter("gender"));

                try {
                    String dobStr = request.getParameter("dob");
                    java.util.Date utilDate = new SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
                    java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
                    counter_staff.setDob(sqlDate);
                } catch (ParseException e) {
                    e.printStackTrace(); // log or handle
                }

                Part file = request.getPart("profilePic");
                try {
                    String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                    if (uploadedFileName != null) {
                        counter_staff.setProfilePic(uploadedFileName);
                    }
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Upload failed: " + e.getMessage());
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                    return;
                }

                counterStaffFacade.edit(counter_staff);
            }
            response.sendRedirect("CounterStaffServlet");
        } else {

            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String phone = request.getParameter("phone");
            String gender = request.getParameter("gender");
            String dobStr = request.getParameter("dob");

            // Parse date of birth
            Date dob = null;
            if (dobStr != null && !dobStr.isEmpty()) {
                dob = Date.valueOf(dobStr); // yyyy-MM-dd
            }

            String uploadedFileName = null;
            Part file = request.getPart("profilePic");

            try {
                uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
            } catch (IllegalArgumentException e) {
                request.setAttribute("error", e.getMessage());
                request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
                return;
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Upload failed: " + e.getMessage());
                request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
                return;
            }

            CounterStaff cs = new CounterStaff();
            cs.setName(name);
            cs.setEmail(email);
            cs.setPassword(password);
            cs.setPhone(phone);
            cs.setGender(gender);
            cs.setDob(dob);
            cs.setProfilePic(uploadedFileName);
            try {
                counterStaffFacade.create(cs);
                request.setAttribute("success", "Counter Staff registered successfully.");

            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Failed to register counter staff: " + e.getMessage());
            }
            request.getRequestDispatcher("manager/register_cs.jsp").include(request, response);
        }
    }

//    retrieve counter staff detail
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");

        if ("edit".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counterStaff = counterStaffFacade.find(id);
            request.setAttribute("counterStaff", counterStaff);
            request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
        } else if ("dashboard".equals(action)) {
            // Load dashboard data for counter staff homepage
            loadDashboardData(request);
            request.getRequestDispatcher("/counter_staff/counter_homepage.jsp").forward(request, response);
        } else {
            // Default: show list
            List<CounterStaff> counterStaff = counterStaffFacade.findAll();
            request.setAttribute("counterStaffList", counterStaff);
            request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
        }
    }
    
    private void loadDashboardData(HttpServletRequest request) {
        try {
            // Get all customers
            List<Customer> allCustomers = customerFacade.findAll();
            int totalCustomers = allCustomers != null ? allCustomers.size() : 0;
            
            // Get all appointments
            List<Appointment> allAppointments = appointmentFacade.findAll();
            int totalAppointments = allAppointments != null ? allAppointments.size() : 0;
            
            // Count appointments by status
            int pendingAppointmentCount = 0;
            int overdueAppointments = 0;
            int completedAppointments = 0;
            int approvedAppointments = 0;
            List<Appointment> recentAppointments = new ArrayList<>();
            List<Appointment> todayAppointments = new ArrayList<>();
            
            if (allAppointments != null) {
                for (Appointment apt : allAppointments) {
                    if (apt.getStatus() != null) {
                        String status = apt.getStatus().toLowerCase();
                        switch (status) {
                            case "pending":
                                pendingAppointmentCount++;
                                break;
                            case "overdue":
                                overdueAppointments++;
                                break;
                            case "completed":
                                completedAppointments++;
                                break;
                            case "approved":
                                approvedAppointments++;
                                break;
                        }
                    }
                }
                // Get recent appointments (limit to 10)
                recentAppointments = allAppointments.size() > 10 
                    ? allAppointments.subList(0, 10) 
                    : allAppointments;
                    
                // For simplicity, using recent appointments as today's appointments
                todayAppointments = recentAppointments;
            }
            
            // Get all payments
            List<Payment> allPayments = paymentFacade.findAll();
            int pendingPaymentCount = 0;
            double totalRevenue = 0.0;
            List<Payment> pendingPayments = new ArrayList<>();
            
            if (allPayments != null) {
                for (Payment payment : allPayments) {
                    if (payment.getStatus() != null) {
                        if ("pending".equalsIgnoreCase(payment.getStatus())) {
                            pendingPaymentCount++;
                            pendingPayments.add(payment);
                        } else if ("completed".equalsIgnoreCase(payment.getStatus()) || 
                                   "paid".equalsIgnoreCase(payment.getStatus())) {
                            totalRevenue += payment.getAmount();
                        }
                    }
                }
            }
            
            // Get all feedbacks
            List<Feedback> allFeedbacks = feedbackFacade.findAll();
            List<Feedback> recentFeedbacks = new ArrayList<>();
            if (allFeedbacks != null) {
                recentFeedbacks = allFeedbacks.size() > 5 
                    ? allFeedbacks.subList(0, 5) 
                    : allFeedbacks;
            }
            
            // Get recent customers (limit to 10)
            List<Customer> recentCustomers = allCustomers != null && allCustomers.size() > 10 
                ? allCustomers.subList(0, 10) 
                : allCustomers;
            
            // Set all attributes for the JSP
            request.setAttribute("totalCustomers", totalCustomers);
            request.setAttribute("totalAppointments", totalAppointments);
            request.setAttribute("pendingAppointmentCount", pendingAppointmentCount);
            request.setAttribute("overdueAppointments", overdueAppointments);
            request.setAttribute("completedAppointments", completedAppointments);
            request.setAttribute("approvedAppointments", approvedAppointments);
            request.setAttribute("pendingPaymentCount", pendingPaymentCount);
            request.setAttribute("totalRevenue", totalRevenue);
            
            // Set list attributes
            request.setAttribute("recentCustomers", recentCustomers);
            request.setAttribute("recentAppointments", recentAppointments);
            request.setAttribute("todayAppointments", todayAppointments);
            request.setAttribute("pendingPayments", pendingPayments);
            request.setAttribute("recentFeedbacks", recentFeedbacks);
            
        } catch (Exception e) {
            e.printStackTrace();
            // Set default values in case of error
            request.setAttribute("totalCustomers", 0);
            request.setAttribute("totalAppointments", 0);
            request.setAttribute("pendingAppointmentCount", 0);
            request.setAttribute("overdueAppointments", 0);
            request.setAttribute("completedAppointments", 0);
            request.setAttribute("approvedAppointments", 0);
            request.setAttribute("pendingPaymentCount", 0);
            request.setAttribute("totalRevenue", 0.0);
            
            request.setAttribute("recentCustomers", new ArrayList<Customer>());
            request.setAttribute("recentAppointments", new ArrayList<Appointment>());
            request.setAttribute("todayAppointments", new ArrayList<Appointment>());
            request.setAttribute("pendingPayments", new ArrayList<Payment>());
            request.setAttribute("recentFeedbacks", new ArrayList<Feedback>());
        }
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
