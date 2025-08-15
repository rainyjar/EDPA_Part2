import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.util.List;
import java.util.stream.Collectors;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.Appointment;
import model.AppointmentFacade;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Manager;
import model.ManagerFacade;
import model.Treatment;
import model.TreatmentFacade;
import java.text.SimpleDateFormat;
import java.util.ArrayList;

@WebServlet(urlPatterns = {"/ManagerServlet"})
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB
        maxRequestSize = 1024 * 1024 * 10) // 10MB

public class ManagerServlet extends HttpServlet {

    @EJB
    private ManagerFacade managerFacade;

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @EJB
    private DoctorFacade doctorFacade;
    
    @EJB
    private AppointmentFacade appointmentFacade;
    
    @EJB
    private TreatmentFacade treatmentFacade;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (!isManagerLoggedIn(request, response)) {
            return;
        }
        String action = request.getParameter("action");

        if ("register".equals(action)) {
            handleRegister(request, response);
        } else if ("update".equals(action)) {
            handleUpdate(request, response);
        } else if ("delete".equals(action)) {
            handleDelete(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        Manager loggedInManager = null;
        String action = request.getParameter("action");

        if (session != null) {
            loggedInManager = (Manager) session.getAttribute("manager");
        }

        if (!isManagerLoggedIn(request, response)) {
            return;
        }

        try {
            if ("view".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                Manager manager = managerFacade.find(id);
                if (manager != null) {
                    request.setAttribute("manager", manager);
                    request.getRequestDispatcher("/manager/view_manager.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
                }
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Manager manager = managerFacade.find(id);

                if (manager != null) {
                    request.setAttribute("manager", manager);
                    request.getRequestDispatcher("/manager/edit_manager.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
                }
            } else if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Manager manager = managerFacade.find(id);

                if (manager != null) {
                    managerFacade.remove(manager);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=manager_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
                }

            } else if ("viewAll".equals(action) || action == null) {
                // Load all staff for manage staff page
                List<Doctor> doctorList = doctorFacade.findAll();
                List<CounterStaff> staffList = counterStaffFacade.findAll();
                List<Manager> managerList = managerFacade.findAll();

                // Debug output
                System.out.println("ManagerServlet: Loading staff data...");
                System.out.println("Doctors found: " + (doctorList != null ? doctorList.size() : "null"));
                System.out.println("Counter Staff found: " + (staffList != null ? staffList.size() : "null"));
                System.out.println("Managers found: " + (managerList != null ? managerList.size() : "null"));

                // Sort by ID (ascending) for consistent ordering
                if (doctorList != null) {
                    doctorList.sort((d1, d2) -> Integer.compare(d1.getId(), d2.getId()));
                }

                if (staffList != null) {
                    staffList.sort((s1, s2) -> Integer.compare(s1.getId(), s2.getId()));
                }

                if (managerList != null) {
                    managerList.sort((m1, m2) -> Integer.compare(m1.getId(), m2.getId()));
                }

                request.setAttribute("doctorList", doctorList);
                request.setAttribute("staffList", staffList);
                request.setAttribute("managerList", managerList);

                System.out.println("ManagerServlet: Forwarding to manage_staff.jsp");
                request.getRequestDispatcher("/manager/manage_staff.jsp").forward(request, response);

            } else if ("viewAppointments".equals(action)) {
                // Get filter parameters
                String searchQuery = request.getParameter("search");
                String statusFilter = request.getParameter("status");
                String doctorFilter = request.getParameter("doctor");
                String treatmentFilter = request.getParameter("treatment");
                String staffFilter = request.getParameter("staff");
                String dateFilter = request.getParameter("date");
                
                // Get all appointments for manager to view
                List<Appointment> allAppointments = appointmentFacade.findAll();
                List<Appointment> filteredAppointments = filterAppointments(allAppointments, searchQuery, statusFilter, 
                                                                           doctorFilter, treatmentFilter, staffFilter, dateFilter);
                
                // Get doctors, treatments, and staff for filter dropdowns
                List<Doctor> doctorList = doctorFacade.findAll();
                List<Treatment> treatmentList = treatmentFacade.findAll();
                List<CounterStaff> staffList = counterStaffFacade.findAll();
                
                // Set attributes for JSP
                request.setAttribute("appointmentList", filteredAppointments);
                request.setAttribute("doctorList", doctorList);
                request.setAttribute("treatmentList", treatmentList);
                request.setAttribute("staffList", staffList);
                
                // Set filter values for form retention
                request.setAttribute("searchQuery", searchQuery);
                request.setAttribute("statusFilter", statusFilter);
                request.setAttribute("doctorFilter", doctorFilter);
                request.setAttribute("treatmentFilter", treatmentFilter);
                request.setAttribute("staffFilter", staffFilter);
                request.setAttribute("dateFilter", dateFilter);
                
                // Forward to view appointments page
                request.getRequestDispatcher("/manager/view_appointments.jsp").forward(request, response);
                
            } else if ("search".equals(action)) {
                // Handle search and filter
                String searchQuery = request.getParameter("search");
                String roleFilter = request.getParameter("role");
                String genderFilter = request.getParameter("gender");

                List<Doctor> doctorList = null;
                List<CounterStaff> staffList = null;
                List<Manager> managerList = null;

                // Apply filters based on role
                if ("all".equals(roleFilter) || "doctor".equals(roleFilter)) {
                    doctorList = searchDoctors(searchQuery, genderFilter);
                }

                if ("all".equals(roleFilter) || "counter_staff".equals(roleFilter)) {
                    staffList = searchCounterStaff(searchQuery, genderFilter);
                }

                if ("all".equals(roleFilter) || "manager".equals(roleFilter)) {
                    managerList = searchManagers(searchQuery, genderFilter);
                }

                request.setAttribute("doctorList", doctorList);
                request.setAttribute("staffList", staffList);
                request.setAttribute("managerList", managerList);

                request.getRequestDispatcher("/manager/manage_staff.jsp").forward(request, response);
            }
        } catch (NumberFormatException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=system_error");
        }

    }

    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Manager manager = new Manager();
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (!populateManagerFromRequest(request, manager, null)) {
            preserveFormData(request);
            request.setAttribute("manager", manager);
            request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
            return;
        }
        managerFacade.create(manager);
        request.setAttribute("success", "Manager registered successfully.");
        request.getRequestDispatcher("manager/register_manager.jsp").forward(request, response);
    }

    private void handleUpdate(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Manager manager = managerFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (manager == null) {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
            return;
        }

        if (!populateManagerFromRequest(request, manager, manager.getEmail())) {
            request.setAttribute("manager", manager);
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=edit&id=" + manager.getId() + "&error=input_invalid");
            return;
        }

        managerFacade.edit(manager);
        request.setAttribute("success", "Manager updated successfully.");
        request.setAttribute("manager", manager);
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=manager_updated");
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Manager manager = managerFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (manager != null) {
            managerFacade.remove(manager);
        }
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=staff_deleted");
    }

    private boolean populateManagerFromRequest(HttpServletRequest request, Manager manager, String existingEmail) throws IOException, ServletException {
        String name = readFormField(request.getPart("name"));
        String email = readFormField(request.getPart("email"));
        String password = readFormField(request.getPart("password"));
        String phone = readFormField(request.getPart("phone"));
        String gender = readFormField(request.getPart("gender"));
        String dobStr = readFormField(request.getPart("dob"));
        String nric = readFormField(request.getPart("nric"));
        String address = readFormField(request.getPart("address"));

        if (name.isEmpty() || email.isEmpty() || password.isEmpty() || phone.isEmpty() || gender == null || dobStr.isEmpty() || nric.isEmpty() || address.isEmpty()) {
            request.setAttribute("error", "All fields are required.");
            return false;
        }

        if (!email.equals(existingEmail) && managerFacade.searchEmail(email) != null) {
            request.setAttribute("error", "Email address is already registered.");
            return false;
        }

        try {
            manager.setName(name);
            manager.setEmail(email);
            manager.setPassword(password);
            manager.setPhone(phone);
            manager.setGender(gender);
            manager.setDob(Date.valueOf(dobStr));
            manager.setIc(nric);
            manager.setAddress(address);

        } catch (Exception e) {
            request.setAttribute("error", "Invalid input format.");
            return false;
        }

        // Handle profile picture
        Part file = request.getPart("profilePic");
        try {
            if (file != null && file.getSize() > 0) {
                String uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                manager.setProfilePic(uploadedFileName);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
            return false;
        }

        return true;
    }

    private void preserveFormData(HttpServletRequest request) throws IOException, ServletException {
        Manager manager = new Manager();
        manager.setName(readFormField(request.getPart("name")));
        manager.setEmail(readFormField(request.getPart("email")));
        manager.setPassword(readFormField(request.getPart("password")));
        manager.setPhone(readFormField(request.getPart("phone")));
        manager.setGender(readFormField(request.getPart("gender")));
        manager.setIc(readFormField(request.getPart("nric")));
        manager.setAddress(readFormField(request.getPart("address")));

        String dobStr = readFormField(request.getPart("dob"));
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                manager.setDob(Date.valueOf(dobStr));
            } catch (Exception ignored) {
            }
        }

        request.setAttribute("manager", manager);
    }

    private String readFormField(Part part) throws IOException {
        if (part == null) {
            return "";
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(part.getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n")).trim();
        }
    }

// Helper methods for search functionality
    private List<Appointment> filterAppointments(List<Appointment> allAppointments, String searchQuery, 
                                          String statusFilter, String doctorFilter, String treatmentFilter, 
                                          String staffFilter, String dateFilter) {
        List<Appointment> filteredAppointments = new ArrayList<>();
        
        // Apply filters
        for (Appointment apt : allAppointments) {
            boolean matches = true;
            
            // Search filter (customer name, email, or appointment ID)
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                String search = searchQuery.toLowerCase().trim();
                boolean searchMatches = false;
                
                // Check appointment ID
                if (String.valueOf(apt.getId()).contains(search)) {
                    searchMatches = true;
                } 
                // Check customer name and email
                else if (apt.getCustomer() != null) {
                    String custName = apt.getCustomer().getName().toLowerCase();
                    String custEmail = apt.getCustomer().getEmail().toLowerCase();
                    if (custName.contains(search) || custEmail.contains(search)) {
                        searchMatches = true;
                    }
                }
                
                if (!searchMatches) {
                    matches = false;
                }
            }
            
            // Status filter
            if (statusFilter != null && !statusFilter.equals("all") && !statusFilter.trim().isEmpty()) {
                String aptStatus = apt.getStatus() != null ? apt.getStatus().toLowerCase() : "pending";
                if (!aptStatus.equals(statusFilter.toLowerCase())) {
                    matches = false;
                }
            }
            
            // Doctor filter
            if (doctorFilter != null && !doctorFilter.equals("all") && !doctorFilter.trim().isEmpty()) {
                try {
                    int doctorId = Integer.parseInt(doctorFilter);
                    if (apt.getDoctor() == null || apt.getDoctor().getId() != doctorId) {
                        matches = false;
                    }
                } catch (NumberFormatException e) {
                    matches = false;
                }
            }
            
            // Treatment filter
            if (treatmentFilter != null && !treatmentFilter.equals("all") && !treatmentFilter.trim().isEmpty()) {
                try {
                    int treatmentId = Integer.parseInt(treatmentFilter);
                    if (apt.getTreatment() == null || apt.getTreatment().getId() != treatmentId) {
                        matches = false;
                    }
                } catch (NumberFormatException e) {
                    matches = false;
                }
            }
            
            // Staff filter
            if (staffFilter != null && !staffFilter.equals("all") && !staffFilter.trim().isEmpty()) {
                if ("not_assigned".equals(staffFilter)) {
                    // Filter for appointments with no assigned counter staff (staffId is null)
                    if (apt.getCounterStaff() != null) {
                        matches = false;
                    }
                } else {
                    try {
                        int staffId = Integer.parseInt(staffFilter);
                        if (apt.getCounterStaff() == null || apt.getCounterStaff().getId() != staffId) {
                            matches = false;
                        }
                    } catch (NumberFormatException e) {
                        matches = false;
                    }
                }
            }
            
            // Date filter
            if (dateFilter != null && !dateFilter.trim().isEmpty()) {
                try {
                    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                    java.util.Date filterDate = sdf.parse(dateFilter);
                    if (apt.getAppointmentDate() == null
                            || !sdf.format(apt.getAppointmentDate()).equals(dateFilter)) {
                        matches = false;
                    }
                } catch (Exception e) {
                    matches = false;
                }
            }
            
            if (matches) {
                filteredAppointments.add(apt);
            }
        }
        
        return filteredAppointments;
    }
    
    private List<Doctor> searchDoctors(String searchQuery, String genderFilter) {
        List<Doctor> allDoctors = doctorFacade.findAll();
        if (allDoctors == null) {
            return null;
        }

        return allDoctors.stream()
                .filter(doctor -> {
                    boolean matchesSearch = searchQuery == null || searchQuery.trim().isEmpty()
                            || doctor.getName().toLowerCase().contains(searchQuery.toLowerCase())
                            || doctor.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

                    boolean matchesGender = "all".equals(genderFilter)
                            || doctor.getGender().equals(genderFilter);

                    return matchesSearch && matchesGender;
                })
                .sorted((d1, d2) -> Integer.compare(d1.getId(), d2.getId())) // Sort by ID for consistency
                .collect(Collectors.toList());
    }

    private List<CounterStaff> searchCounterStaff(String searchQuery, String genderFilter) {
        List<CounterStaff> allStaff = counterStaffFacade.findAll();
        if (allStaff == null) {
            return null;
        }

        return allStaff.stream()
                .filter(staff -> {
                    boolean matchesSearch = searchQuery == null || searchQuery.trim().isEmpty()
                            || staff.getName().toLowerCase().contains(searchQuery.toLowerCase())
                            || staff.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

                    boolean matchesGender = "all".equals(genderFilter)
                            || staff.getGender().equals(genderFilter);

                    return matchesSearch && matchesGender;
                })
                .sorted((s1, s2) -> Integer.compare(s1.getId(), s2.getId())) // Sort by ID for consistency
                .collect(Collectors.toList());
    }

    private List<Manager> searchManagers(String searchQuery, String genderFilter) {
        List<Manager> allManagers = managerFacade.findAll();
        if (allManagers == null) {
            return null;
        }

        return allManagers.stream()
                .filter(mgr -> {
                    boolean matchesSearch = searchQuery == null || searchQuery.trim().isEmpty()
                            || mgr.getName().toLowerCase().contains(searchQuery.toLowerCase())
                            || mgr.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

                    boolean matchesGender = "all".equals(genderFilter)
                            || mgr.getGender().equals(genderFilter);

                    return matchesSearch && matchesGender;
                })
                .sorted((m1, m2) -> Integer.compare(m1.getId(), m2.getId())) // Sort by ID for consistency
                .collect(Collectors.toList());
    }

    private boolean isManagerLoggedIn(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("manager") == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return false;
            }
            return true;
        } catch (IllegalStateException e) {
            // Already committed response (e.g., forward was called), can't redirect
            System.out.println("Warning: Response already committed. Skipping redirect.");
            return false;
        }
    }

    @Override
    public String getServletInfo() {
        return "ManagerServlet - Handles CRUD operations for managers";
    }
}
