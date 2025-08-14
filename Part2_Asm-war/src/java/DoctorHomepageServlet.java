import java.io.IOException;
import java.util.ArrayList;
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
import model.Appointment;
import model.AppointmentFacade;
import model.Doctor;
import model.Feedback;
import model.Treatment;
import model.Customer;
import model.CustomerFacade;
import model.FeedbackFacade;
import model.TreatmentFacade;

@WebServlet(urlPatterns = {"/DoctorHomepageServlet"})
public class DoctorHomepageServlet extends HttpServlet {

    @EJB
    private TreatmentFacade treatmentFacade;

    @EJB
    private FeedbackFacade feedbackFacade;

    @EJB
    private CustomerFacade customerFacade;

    @EJB
    private AppointmentFacade appointmentFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");

        if (loggedInDoctor == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");

        if ("dashboard".equals(action)) {
            loadDashboardData(request, loggedInDoctor);
            request.getRequestDispatcher("/doctor/doctor_homepage.jsp").forward(request, response);
        } else {
            // Default action
            loadDashboardData(request, loggedInDoctor);
            request.getRequestDispatcher("/doctor/doctor_homepage.jsp").forward(request, response);
        }
    }

    private void loadDashboardData(HttpServletRequest request, Doctor doctor) {
        try {
            System.out.println("Loading dashboard data for doctor: " + doctor.getName());

            // Get today's date
            Calendar cal = Calendar.getInstance();
            Date today = cal.getTime();
            cal.set(Calendar.HOUR_OF_DAY, 0);
            cal.set(Calendar.MINUTE, 0);
            cal.set(Calendar.SECOND, 0);
            cal.set(Calendar.MILLISECOND, 0);
            Date startOfDay = cal.getTime();
            cal.add(Calendar.DAY_OF_MONTH, 1);
            Date startOfNextDay = cal.getTime();

            // Get start of month
            cal.setTime(today);
            cal.set(Calendar.DAY_OF_MONTH, 1);
            Date startOfMonth = cal.getTime();

            // Get all appointments for this doctor
            List<Appointment> allAppointments = appointmentFacade.findAll();
            List<Appointment> myAppointments = new ArrayList<>();
            List<Appointment> myTodayAppointments = new ArrayList<>();
            List<Appointment> myRecentAppointments = new ArrayList<>();

            int myApprovedAppointments = 0;
            int myCompletedAppointments = 0;
            double totalChargesIssued = 0.0;

            // Filter appointments for this doctor
            for (Appointment apt : allAppointments) {
                if (apt.getDoctor() != null && apt.getDoctor().getId() == doctor.getId()) {
                    myAppointments.add(apt);

                    // Check if it's today's appointment
                    if (apt.getAppointmentDate() != null
                            && apt.getAppointmentDate().compareTo(startOfDay) >= 0
                            && apt.getAppointmentDate().compareTo(startOfNextDay) < 0) {
                        myTodayAppointments.add(apt);
                    }

                    // Count approved appointments
                    if ("approved".equalsIgnoreCase(apt.getStatus())) {
                        myApprovedAppointments++;
                    }

                    // Count completed appointments this month
                    if ("completed".equalsIgnoreCase(apt.getStatus())
                            && apt.getAppointmentDate() != null
                            && apt.getAppointmentDate().compareTo(startOfMonth) >= 0) {
                        myCompletedAppointments++;

                        // Calculate charges issued (you might want to get this from receipts)
                        if (apt.getTreatment() != null) {
                            totalChargesIssued += apt.getTreatment().getBaseConsultationCharge();
                        }
                    }
                }
            }

            // Get recent appointments (last 10)
            myRecentAppointments = myAppointments.subList(
                    Math.max(0, myAppointments.size() - 10),
                    myAppointments.size()
            );

            // Get total patients for this doctor
            List<Customer> allCustomers = customerFacade.findAll();
            int totalPatients = allCustomers.size(); // You might want to filter by patients who have appointments with this doctor

            // Get treatments managed by this doctor
            List<Treatment> allTreatments = treatmentFacade.findAll();
            List<Treatment> myTreatments = new ArrayList<>();
            for (Treatment treatment : allTreatments) {
                if (treatment.getDoctors() != null && treatment.getDoctors().contains(doctor)) {
                    myTreatments.add(treatment);
                }
            }

            // Get recent feedback for this doctor
            List<Feedback> allFeedbacks = feedbackFacade.findAll();
            List<Feedback> myRecentFeedbacks = new ArrayList<>();
            for (Feedback feedback : allFeedbacks) {
                if (feedback.getToDoctor() != null && feedback.getToDoctor().getId() == doctor.getId()) {
                    myRecentFeedbacks.add(feedback);
                }
            }

            // Limit to recent 5 feedbacks
            if (myRecentFeedbacks.size() > 5) {
                myRecentFeedbacks = myRecentFeedbacks.subList(
                        myRecentFeedbacks.size() - 5,
                        myRecentFeedbacks.size()
                );
            }

            // Set request attributes
            request.setAttribute("totalPatients", totalPatients);
            request.setAttribute("myTotalAppointments", myAppointments.size());
            request.setAttribute("myApprovedAppointments", myApprovedAppointments);
            request.setAttribute("myCompletedAppointments", myCompletedAppointments);
            request.setAttribute("treatmentsManaged", myTreatments.size());
            request.setAttribute("totalChargesIssued", totalChargesIssued);

            request.setAttribute("myTodayAppointments", myTodayAppointments);
            request.setAttribute("myPendingAppointments", myAppointments); // You can filter further if needed
            request.setAttribute("myRecentAppointments", myRecentAppointments);
            request.setAttribute("myTreatments", myTreatments);
            request.setAttribute("myRecentFeedbacks", myRecentFeedbacks);

            System.out.println("Dashboard data loaded successfully:");
            System.out.println("- Total Patients: " + totalPatients);
            System.out.println("- My Total Appointments: " + myAppointments.size());
            System.out.println("- My Approved Appointments: " + myApprovedAppointments);
            System.out.println("- Today's Appointments: " + myTodayAppointments.size());
            System.out.println("- Treatments Managed: " + myTreatments.size());
            System.out.println("- Total Charges Issued: " + totalChargesIssued);

        } catch (Exception e) {
            System.err.println("Error loading dashboard data: " + e.getMessage());
            e.printStackTrace();

            // Set default values in case of error
            request.setAttribute("totalPatients", 0);
            request.setAttribute("myTotalAppointments", 0);
            request.setAttribute("myApprovedAppointments", 0);
            request.setAttribute("myCompletedAppointments", 0);
            request.setAttribute("treatmentsManaged", 0);
            request.setAttribute("totalChargesIssued", 0.0);

            request.setAttribute("myTodayAppointments", new ArrayList<>());
            request.setAttribute("myPendingAppointments", new ArrayList<>());
            request.setAttribute("myRecentAppointments", new ArrayList<>());
            request.setAttribute("myTreatments", new ArrayList<>());
            request.setAttribute("myRecentFeedbacks", new ArrayList<>());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
