/*
 * Customer Servlet for Counter Staff Operations
 * Handles customer management operations by counter staff including search functionality
 */

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.Customer;
import model.CustomerFacade;
import model.CounterStaff;
import model.Appointment;
import model.AppointmentFacade;
import model.Doctor;

@WebServlet(urlPatterns = {"/CustomerServlet"})
@MultipartConfig
public class CustomerServlet extends HttpServlet {

    @EJB
    private CustomerFacade customerFacade;
    
    @EJB
    private AppointmentFacade appointmentFacade;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
        Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");

        // Allow both counter staff and doctors to access customer search
        if (loggedInStaff == null && loggedInDoctor == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "viewAll";

        try {
            switch (action) {
                case "viewAll":
                    handleViewAllCustomers(request, response);
                    break;
                case "view":
                    handleViewCustomer(request, response);
                    break;
                case "add":
                    handleAddCustomerForm(request, response);
                    break;
                case "edit":
                    handleEditCustomerForm(request, response);
                    break;
                case "delete":
                    handleDeleteCustomer(request, response);
                    break;
                case "search":
                    handleCustomerSearch(request, response);
                    break;
                case "details":
                    handleCustomerDetails(request, response);
                    break;
                case "history":
                    handleCustomerHistory(request, response);
                    break;
                default:
                    handleViewAllCustomers(request, response);
                    break;
            }
        } catch (NumberFormatException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=system_error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

        if (loggedInStaff == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");
        
        try {
            switch (action) {
                case "create":
                    handleCreateCustomer(request, response, loggedInStaff);
                    break;
                case "update":
                    handleUpdateCustomer(request, response, loggedInStaff);
                    break;
                default:
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll");
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=system_error");
        }
    }

    private void handleViewAllCustomers(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<Customer> customers = customerFacade.findAll();
            request.setAttribute("customerList", customers);
            
            // Add message if no customers found
            if (customers == null || customers.isEmpty()) {
                request.setAttribute("infoMessage", "No customers found in the database.");
            }
            
            request.getRequestDispatcher("/counter_staff/manage_customer.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "database_error");
            request.setAttribute("customerList", new ArrayList<Customer>());
            request.getRequestDispatcher("/counter_staff/manage_customer.jsp").forward(request, response);
        }
    }

    private void handleViewCustomer(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr != null) {
            try {
                int customerId = Integer.parseInt(idStr);
                Customer customer = customerFacade.find(customerId);
                if (customer != null) {
                    request.setAttribute("viewCustomer", customer);
                    request.getRequestDispatcher("/counter_staff/view_customer.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
                }
            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=invalid_id");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=missing_id");
        }
    }

    private void handleAddCustomerForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/counter_staff/register_customer.jsp").forward(request, response);
    }

    private void handleEditCustomerForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr != null) {
            try {
                int customerId = Integer.parseInt(idStr);
                Customer customer = customerFacade.find(customerId);
                if (customer != null) {
                    request.setAttribute("customer", customer);
                    request.getRequestDispatcher("/counter_staff/edit_customer.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
                }
            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=invalid_id");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=missing_id");
        }
    }

    private void handleCreateCustomer(HttpServletRequest request, HttpServletResponse response, CounterStaff staff)
            throws ServletException, IOException {
        try {
            // Validate input
            String validationError = validateCustomerData(request);
            if (validationError != null) {
                request.setAttribute("error", validationError);
                preserveFormData(request);
                request.getRequestDispatcher("/counter_staff/register_customer.jsp").forward(request, response);
                return;
            }

            String name = request.getParameter("name").trim();
            String email = request.getParameter("email").trim();
            String password = request.getParameter("password");
            String phone = request.getParameter("phone").trim();
            String gender = request.getParameter("gender");
            String dobStr = request.getParameter("dob");

            // Check if customer with email already exists
            Customer existingCustomer = customerFacade.searchEmail(email);
            if (existingCustomer != null) {
                request.setAttribute("error", "A customer with this email already exists.");
                preserveFormData(request);
                request.getRequestDispatcher("/counter_staff/register_customer.jsp").forward(request, response);
                return;
            }

            Date dob = null;
            if (dobStr != null && !dobStr.isEmpty()) {
                dob = Date.valueOf(dobStr);
            }

            // Handle profile picture upload
            String uploadedFileName = null;
            Part file = request.getPart("profilePic");
            if (file != null && file.getSize() > 0) {
                try {
                    uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                } catch (Exception e) {
                    request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
                    preserveFormData(request);
                    request.getRequestDispatcher("/counter_staff/register_customer.jsp").forward(request, response);
                    return;
                }
            }

            Customer customer = new Customer();
            customer.setName(name);
            customer.setEmail(email);
            customer.setPassword(password);
            customer.setPhone(phone);
            customer.setGender(gender);
            customer.setDob(dob);
            customer.setProfilePic(uploadedFileName);

            customerFacade.create(customer);
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&success=customer_registered");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to register customer: " + e.getMessage());
            preserveFormData(request);
            request.getRequestDispatcher("/counter_staff/register_customer.jsp").forward(request, response);
        }
    }

    private void handleUpdateCustomer(HttpServletRequest request, HttpServletResponse response, CounterStaff staff)
            throws ServletException, IOException {
        try {
            int customerId = Integer.parseInt(request.getParameter("id"));
            Customer customer = customerFacade.find(customerId);
            
            if (customer == null) {
                response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
                return;
            }

            // Validate input
            String validationError = validateCustomerData(request);
            if (validationError != null) {
                request.setAttribute("error", validationError);
                request.setAttribute("customer", customer);
                request.getRequestDispatcher("/counter_staff/edit_customer.jsp").forward(request, response);
                return;
            }

            String name = request.getParameter("name").trim();
            String email = request.getParameter("email").trim();
            String password = request.getParameter("password");
            String phone = request.getParameter("phone").trim();
            String gender = request.getParameter("gender");
            String dobStr = request.getParameter("dob");

            // Check if email is taken by another customer
            Customer existingCustomer = customerFacade.searchEmail(email);
            if (existingCustomer != null && existingCustomer.getId() != customerId) {
                request.setAttribute("error", "Email address is already taken by another customer.");
                request.setAttribute("customer", customer);
                request.getRequestDispatcher("/counter_staff/edit_customer.jsp").forward(request, response);
                return;
            }

            customer.setName(name);
            customer.setEmail(email);
            if (password != null && !password.trim().isEmpty()) {
                customer.setPassword(password);
            }
            customer.setPhone(phone);
            customer.setGender(gender);
            
            if (dobStr != null && !dobStr.isEmpty()) {
                customer.setDob(Date.valueOf(dobStr));
            }

            // Handle profile picture upload
            Part file = request.getPart("profilePic");
            if (file != null && file.getSize() > 0) {
                try {
                    String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                    if (uploadedFileName != null) {
                        customer.setProfilePic(uploadedFileName);
                    }
                } catch (Exception e) {
                    request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
                    request.setAttribute("customer", customer);
                    request.getRequestDispatcher("/counter_staff/edit_customer.jsp").forward(request, response);
                    return;
                }
            }

            customerFacade.edit(customer);
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&success=customer_updated");

        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=system_error");
        }
    }

    private void handleDeleteCustomer(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (idStr != null) {
            try {
                int customerId = Integer.parseInt(idStr);
                Customer customer = customerFacade.find(customerId);
                if (customer != null) {
                    customerFacade.remove(customer);
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&success=customer_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
                }
            } catch (NumberFormatException e) {
                response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=invalid_id");
            }
        } else {
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=missing_id");
        }
    }

    /**
     * Handle customer search requests with multiple search criteria
     * Combined from CustomerSearchServlet functionality
     */
    private void handleCustomerSearch(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String acceptHeader = request.getHeader("Accept");
        boolean isAjaxRequest = acceptHeader != null && acceptHeader.contains("application/json");
        
        System.out.println("=== CustomerServlet Search Debug ===");
        System.out.println("Accept Header: " + acceptHeader);
        System.out.println("Is AJAX Request: " + isAjaxRequest);
        
        try {
            String searchTerm = request.getParameter("search");
            String genderFilter = request.getParameter("gender");
            String searchType = request.getParameter("type"); // "name", "email", "phone", "id", or "all"
            
            System.out.println("Search Term: " + searchTerm);
            System.out.println("Gender Filter: " + genderFilter);
            System.out.println("Search Type: " + searchType);
            
            List<Customer> customers = new ArrayList<>();
            
            if (searchTerm != null && !searchTerm.trim().isEmpty()) {
                String trimmedSearch = searchTerm.trim();
                
                // Determine search type if not specified
                if (searchType == null || "all".equals(searchType)) {
                    searchType = detectSearchType(trimmedSearch);
                }
                
                System.out.println("Detected/Final Search Type: " + searchType);
                
                // Perform search based on type
                switch (searchType) {
                    case "id":
                        try {
                            int customerId = Integer.parseInt(trimmedSearch);
                            Customer customer = customerFacade.find(customerId);
                            if (customer != null) {
                                customers.add(customer);
                                System.out.println("Found customer by ID: " + customer.getName());
                            } else {
                                System.out.println("No customer found with ID: " + customerId);
                            }
                        } catch (NumberFormatException e) {
                            // Invalid ID format, search by name instead
                            System.out.println("Invalid ID format, searching by name instead");
                            customers = searchCustomersByName(trimmedSearch);
                        }
                        break;
                    case "email":
                        customers = searchCustomersByEmail(trimmedSearch);
                        System.out.println("Email search returned " + customers.size() + " results");
                        break;
                    case "phone":
                        customers = searchCustomersByPhone(trimmedSearch);
                        System.out.println("Phone search returned " + customers.size() + " results");
                        break;
                    case "name":
                    default:
                        customers = searchCustomersByName(trimmedSearch);
                        System.out.println("Name search returned " + customers.size() + " results");
                        break;
                }
            } else {
                // No search term provided, get all customers
                customers = customerFacade.findAll();
                System.out.println("No search term provided, getting all customers: " + customers.size());
            }
            
            // Apply gender filter if specified
            if (genderFilter != null && !"all".equals(genderFilter)) {
                int originalSize = customers.size();
                customers = customers.stream()
                    .filter(c -> genderFilter.equals(c.getGender()))
                    .collect(java.util.stream.Collectors.toList());
                System.out.println("Gender filter applied, results reduced from " + originalSize + " to " + customers.size());
            }
            
            System.out.println("Final result count: " + customers.size());
            
            if (isAjaxRequest) {
                // Return JSON for AJAX requests
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                PrintWriter out = response.getWriter();
                
                StringBuilder json = new StringBuilder();
                json.append("{\"customers\": [");
            
                for (int i = 0; i < customers.size(); i++) {
                    Customer customer = customers.get(i);
                    if (i > 0) json.append(",");
                    
                    // Get appointment count for this customer
                    int appointmentCount = 0;
                    try {
                        List<Appointment> customerAppointments = appointmentFacade.findByCustomer(customer);
                        appointmentCount = customerAppointments != null ? customerAppointments.size() : 0;
                    } catch (Exception e) {
                        System.err.println("Error getting appointment count for customer " + customer.getId() + ": " + e.getMessage());
                    }
                    
                    json.append("{");
                    json.append("\"id\": ").append(customer.getId()).append(",");
                    json.append("\"name\": \"").append(escapeJson(customer.getName())).append("\",");
                    json.append("\"email\": \"").append(escapeJson(customer.getEmail())).append("\",");
                    json.append("\"phone\": \"").append(escapeJson(customer.getPhone() != null ? customer.getPhone() : "")).append("\",");
                    json.append("\"phoneNumber\": \"").append(escapeJson(customer.getPhone() != null ? customer.getPhone() : "")).append("\",");
                    json.append("\"gender\": \"").append(escapeJson(customer.getGender() != null ? customer.getGender() : "")).append("\",");
                    json.append("\"dob\": \"").append(customer.getDob() != null ? customer.getDob().toString() : "").append("\",");
                    json.append("\"appointmentCount\": ").append(appointmentCount);
                    json.append("}");
                }
                
                json.append("]}");
                
                System.out.println("Returning JSON response: " + json.toString());
                out.write(json.toString());
            } else {
                // Forward to JSP for form submissions
                request.setAttribute("customerList", customers);
                request.setAttribute("searchQuery", searchTerm != null ? searchTerm : "");
                request.setAttribute("genderFilter", genderFilter != null ? genderFilter : "all");
                
                // Add message if no customers found
                if (customers == null || customers.isEmpty()) {
                    if (searchTerm != null && !searchTerm.trim().isEmpty()) {
                        request.setAttribute("infoMessage", "No customers found matching your search criteria.");
                    } else {
                        request.setAttribute("infoMessage", "No customers found in the database.");
                    }
                }
                
                request.getRequestDispatcher("/counter_staff/manage_customer.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("Error in customer search: " + e.getMessage());
            if (isAjaxRequest) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                PrintWriter out = response.getWriter();
                out.write("{\"error\": \"Search failed: " + e.getMessage() + "\", \"customers\": []}");
            } else {
                request.setAttribute("error", "database_error");
                request.setAttribute("customerList", new ArrayList<Customer>());
                request.getRequestDispatcher("/counter_staff/manage_customer.jsp").forward(request, response);
            }
        }
    }

    /**
     * Handle customer details request
     */
    private void handleCustomerDetails(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String idStr = request.getParameter("id");
            if (idStr == null || idStr.trim().isEmpty()) {
                out.write("{\"error\": \"Customer ID is required\"}");
                return;
            }
            
            int customerId = Integer.parseInt(idStr);
            Customer customer = customerFacade.find(customerId);
            
            if (customer == null) {
                out.write("{\"error\": \"Customer not found\"}");
                return;
            }
            
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"id\": ").append(customer.getId()).append(",");
            json.append("\"name\": \"").append(escapeJson(customer.getName())).append("\",");
            json.append("\"email\": \"").append(escapeJson(customer.getEmail())).append("\",");
            json.append("\"phone\": \"").append(escapeJson(customer.getPhone() != null ? customer.getPhone() : "")).append("\",");
            json.append("\"gender\": \"").append(escapeJson(customer.getGender() != null ? customer.getGender() : "")).append("\",");
            json.append("\"dob\": \"").append(customer.getDob() != null ? customer.getDob().toString() : "").append("\",");
            json.append("\"profilePic\": \"").append(escapeJson(customer.getProfilePic() != null ? customer.getProfilePic() : "")).append("\"");
            json.append("}");
            
            out.write(json.toString());
            
        } catch (NumberFormatException e) {
            out.write("{\"error\": \"Invalid customer ID\"}");
        } catch (Exception e) {
            e.printStackTrace();
            out.write("{\"error\": \"Failed to retrieve customer details\"}");
        }
    }

    /**
     * Handle customer history request
     */
    private void handleCustomerHistory(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String idStr = request.getParameter("customerId");
            if (idStr == null || idStr.trim().isEmpty()) {
                out.write("{\"error\": \"Customer ID is required\", \"appointments\": []}");
                return;
            }
            
            int customerId = Integer.parseInt(idStr);
            Customer customer = customerFacade.find(customerId);
            
            if (customer == null) {
                out.write("{\"error\": \"Customer not found\", \"appointments\": []}");
                return;
            }
            
            // Get customer appointments
            List<Appointment> appointments = appointmentFacade.findByCustomer(customer);
            
            String statusFilter = request.getParameter("status");
            if (statusFilter != null && !statusFilter.equals("all")) {
                appointments = appointments.stream()
                    .filter(a -> statusFilter.equals(a.getStatus()))
                    .collect(java.util.stream.Collectors.toList());
            }
            
            StringBuilder json = new StringBuilder();
            json.append("{\"appointments\": [");
            
            for (int i = 0; i < appointments.size(); i++) {
                Appointment apt = appointments.get(i);
                if (i > 0) json.append(",");
                
                json.append("{");
                json.append("\"id\": ").append(apt.getId()).append(",");
                json.append("\"date\": \"").append(apt.getAppointmentDate() != null ? apt.getAppointmentDate().toString() : "").append("\",");
                json.append("\"time\": \"").append(apt.getAppointmentTime() != null ? apt.getAppointmentTime().toString() : "").append("\",");
                json.append("\"status\": \"").append(escapeJson(apt.getStatus() != null ? apt.getStatus() : "")).append("\",");
                json.append("\"doctor\": \"").append(escapeJson(apt.getDoctor() != null ? apt.getDoctor().getName() : "")).append("\",");
                json.append("\"treatment\": \"").append(escapeJson(apt.getTreatment() != null ? apt.getTreatment().getName() : "")).append("\"");
                json.append("}");
            }
            
            json.append("]}");
            out.write(json.toString());
            
        } catch (NumberFormatException e) {
            out.write("{\"error\": \"Invalid customer ID\", \"appointments\": []}");
        } catch (Exception e) {
            e.printStackTrace();
            out.write("{\"error\": \"Failed to retrieve appointment history\", \"appointments\": []}");
        }
    }

    // Helper methods
    private String detectSearchType(String searchTerm) {
        if (searchTerm.matches("\\d+")) {
            return "id";
        } else if (searchTerm.contains("@")) {
            return "email";
        } else if (searchTerm.matches("\\+?[0-9\\-\\s]+")) {
            return "phone";
        } else {
            return "name";
        }
    }
    
    private List<Customer> searchCustomersByName(String name) {
        return customerFacade.searchByName(name);
    }
    
    private List<Customer> searchCustomersByEmail(String email) {
        Customer customer = customerFacade.searchEmail(email);
        List<Customer> results = new ArrayList<>();
        if (customer != null) {
            results.add(customer);
        }
        return results;
    }
    
    private List<Customer> searchCustomersByPhone(String phone) {
        Customer customer = customerFacade.searchByPhoneNumber(phone);
        List<Customer> results = new ArrayList<>();
        if (customer != null) {
            results.add(customer);
        }
        return results;
    }
    
    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }

    private String validateCustomerData(HttpServletRequest request) {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String phone = request.getParameter("phone");
        String gender = request.getParameter("gender");
        String dobStr = request.getParameter("dob");

        if (name == null || name.trim().isEmpty()) {
            return "Full name is required";
        }
        if (email == null || email.trim().isEmpty()) {
            return "Email address is required";
        }
        if (password == null || password.trim().isEmpty()) {
            return "Password is required";
        }
        if (phone == null || phone.trim().isEmpty()) {
            return "Phone number is required";
        }
        if (gender == null || gender.trim().isEmpty()) {
            return "Gender is required";
        }
        if (dobStr == null || dobStr.trim().isEmpty()) {
            return "Date of birth is required";
        }

        // Validate email format
        if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
            return "Invalid email format";
        }

        // Validate password length
        if (password.length() < 6) {
            return "Password must be at least 6 characters long";
        }

        return null; // No validation errors
    }

    private void preserveFormData(HttpServletRequest request) {
        request.setAttribute("name", request.getParameter("name"));
        request.setAttribute("email", request.getParameter("email"));
        request.setAttribute("phone", request.getParameter("phone"));
        request.setAttribute("gender", request.getParameter("gender"));
        request.setAttribute("dob", request.getParameter("dob"));
    }
}
