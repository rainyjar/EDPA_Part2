/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

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
import model.Customer;
import model.Doctor;
import model.DoctorFacade;
import model.Treatment;
import model.TreatmentFacade;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/CustomerHomepageServlet"})
public class CustomerHomepageServlet extends HttpServlet {

    @EJB
    private TreatmentFacade treatmentFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private AppointmentFacade appointmentFacade;

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
     * methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check if customer is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("customer") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Customer loggedInCustomer = (Customer) session.getAttribute("customer");

        List<Doctor> doctorList = doctorFacade.findAll();
        List<Treatment> treatmentList = treatmentFacade.findAll();

        // Get customer's appointments with comprehensive validation for reminders
        List<Appointment> customerAppointments = appointmentFacade.findByCustomer(loggedInCustomer);
        List<Appointment> upcomingAppointments = new ArrayList<>();
        List<Appointment> urgentReminders = new ArrayList<>();
        List<Appointment> overdueAppointments = new ArrayList<>();
        List<Appointment> rescheduleAppointments = new ArrayList<>();

        if (customerAppointments != null) {
            Date today = new Date();
            Calendar cal = Calendar.getInstance();
            cal.setTime(today);

            // Set time to start of today for accurate date comparison
            cal.set(Calendar.HOUR_OF_DAY, 0);
            cal.set(Calendar.MINUTE, 0);
            cal.set(Calendar.SECOND, 0);
            cal.set(Calendar.MILLISECOND, 0);
            Date todayStart = cal.getTime();

            cal.add(Calendar.DAY_OF_MONTH, 7); // Next 7 days
            Date nextWeek = cal.getTime();

            cal.setTime(todayStart);
            cal.add(Calendar.DAY_OF_MONTH, 2); // Next 2 days for urgent reminders
            Date urgentDate = cal.getTime();

            for (Appointment apt : customerAppointments) {
                if (apt.getAppointmentDate() != null && apt.getStatus() != null) {
                    String status = apt.getStatus().trim().toLowerCase();

                    // Skip completed, cancelled, or invalid appointments
                    if ("completed".equals(status) || "cancelled".equals(status)) {
                        continue;
                    }

                    // SIMPLIFIED overdue detection - primarily check database status
                    boolean isDateOverdue = apt.getAppointmentDate().before(todayStart);

                    System.out.println("DEBUG Appointment ID " + apt.getId() + ":");
                    System.out.println("  - Status: " + status);
                    System.out.println("  - Date: " + apt.getAppointmentDate());
                    System.out.println("  - Today start: " + todayStart);
                    System.out.println("  - Is date before today: " + isDateOverdue);

                    if ("reschedule".equals(status)) {
                        System.out.println("  -> ADDING TO RESCHEDULE LIST (status = reschedule)");
                        rescheduleAppointments.add(apt);
                        urgentReminders.add(apt); // optionally
                        continue;
                    }

                    // PRIORITY 1: Check if appointment is explicitly marked as "overdue" in database
                    if ("overdue".equals(status)) {
                        System.out.println("  -> ADDING TO OVERDUE LIST (database status = overdue)");
                        overdueAppointments.add(apt);
                        urgentReminders.add(apt);
                        continue;
                    }

                    // PRIORITY 2: Check for logically overdue appointments (past due date but not marked)
                    if (isDateOverdue
                            && ("approved".equals(status) || "confirmed".equals(status) || "pending".equals(status) || "reschedule".equals(status))) {
                        System.out.println("  -> ADDING TO OVERDUE LIST (past due date)");
                        overdueAppointments.add(apt);
                        urgentReminders.add(apt);
                        continue;
                    }

                    // Process upcoming appointments (approved/confirmed only)
                    if (("approved".equals(status) || "confirmed".equals(status))
                            && apt.getAppointmentDate().after(todayStart) && apt.getAppointmentDate().before(nextWeek)) {
                        System.out.println("  -> ADDING TO UPCOMING LIST");
                        upcomingAppointments.add(apt);

                        // Check if appointment needs urgent reminder (within next 2 days)
                        if (apt.getAppointmentDate().before(urgentDate)) {
                            urgentReminders.add(apt);
                        }
                    }

                    // Handle reschedule requests as urgent reminders
//                    if ("reschedule".equals(status) && apt.getAppointmentDate().after(todayStart)) {
//                        System.out.println("  -> ADDING TO UPCOMING LIST (reschedule status)");
//                        upcomingAppointments.add(apt);
//                        urgentReminders.add(apt); // Always urgent for rescheduling
//                    }

                    System.out.println("  -> Final decision: Not added to any list");
                }
            }
        }

        System.out.println("=== APPOINTMENT REMINDER SUMMARY ===");
        System.out.println("Doctor list size: " + (doctorList != null ? doctorList.size() : "null"));
        System.out.println("Treatment list size: " + (treatmentList != null ? treatmentList.size() : "null"));
        System.out.println("Upcoming appointments: " + upcomingAppointments.size());
        System.out.println("Urgent reminders: " + urgentReminders.size());
        System.out.println("Overdue appointments: " + overdueAppointments.size());

        if (overdueAppointments.size() > 0) {
            System.out.println("OVERDUE APPOINTMENTS DETAILS:");
            for (Appointment overdue : overdueAppointments) {
                System.out.println("  - ID: " + overdue.getId() + ", Status: " + overdue.getStatus()
                        + ", Date: " + overdue.getAppointmentDate()
                        + ", Treatment: " + (overdue.getTreatment() != null ? overdue.getTreatment().getName() : "N/A"));
            }
        }

        if (upcomingAppointments.size() > 0) {
            System.out.println("UPCOMING APPOINTMENTS DETAILS:");
            for (Appointment upcoming : upcomingAppointments) {
                System.out.println("  - ID: " + upcoming.getId() + ", Status: " + upcoming.getStatus()
                        + ", Date: " + upcoming.getAppointmentDate()
                        + ", Treatment: " + (upcoming.getTreatment() != null ? upcoming.getTreatment().getName() : "N/A"));
            }
        }
        System.out.println("====================================");

        if (treatmentList != null) {
            for (Treatment t : treatmentList) {
                System.out.println("Treatment: " + t.getName());
            }
        }
        if (doctorList != null) {
            for (Doctor t : doctorList) {
                System.out.println("Doctor: " + t.getName());
            }
        }

        request.setAttribute("doctorList", doctorList);
        request.setAttribute("treatmentList", treatmentList);
        request.setAttribute("upcomingAppointments", upcomingAppointments);
        request.setAttribute("urgentReminders", urgentReminders);
        request.setAttribute("overdueAppointments", overdueAppointments);
        request.setAttribute("rescheduleAppointments", rescheduleAppointments);

        request.getRequestDispatcher("customer/cust_homepage.jsp").forward(request, response);

    }

    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
