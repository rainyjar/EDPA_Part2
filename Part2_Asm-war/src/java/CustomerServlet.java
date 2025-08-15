
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
import model.CounterStaff;
import model.Customer;
import model.CustomerFacade;
import model.Doctor;
import model.Manager;

@WebServlet(urlPatterns = {"/CustomerServlet"})
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB
        maxRequestSize = 1024 * 1024 * 10) // 10MB

public class CustomerServlet extends HttpServlet {

    @EJB
    private CustomerFacade customerFacade;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (!isStaffLoggedIn(request, response)) {
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
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        CounterStaff loggedInStaff = null;
        String action = request.getParameter("action");

        if (session != null) {
            loggedInStaff = (CounterStaff) session.getAttribute("staff");
        }

        if (!isStaffLoggedIn(request, response)) {
            return;
        }

        try {
            if ("view".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                Customer customer = customerFacade.find(id);
                if (customer != null) {
                    request.setAttribute("customer", customer);
                    request.getRequestDispatcher("/counter_staff/view_customer.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
                }
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Customer customer = customerFacade.find(id);

                if (customer != null) {
                    request.setAttribute("customer", customer);
                    request.getRequestDispatcher("/counter_staff/edit_customer.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
                }
            } else if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                Customer customer = customerFacade.find(id);

                if (customer != null) {
                    customerFacade.remove(customer);
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&success=customer_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
                }

            } else if ("viewAll".equals(action) || action == null) {
                List<Customer> customerList = customerFacade.findAll();

                // Debug output
                System.out.println("CustomerServlet: Loading customer data...");
                System.out.println("Customer found: " + (customerList != null ? customerList.size() : "null"));

                // Sort by ID (ascending) for consistent ordering
                if (customerList != null) {
                    customerList.sort((m1, m2) -> Integer.compare(m1.getId(), m2.getId()));
                }

                request.setAttribute("customerList", customerList);

                System.out.println("CustomerServlet: Forwarding to manage_customer.jsp");
                request.getRequestDispatcher("/counter_staff/manage_customer.jsp").forward(request, response);

            } else if ("search".equals(action)) {
                // Handle search and filter
                String searchQuery = request.getParameter("search");
                String genderFilter = request.getParameter("gender");

                // Debug output
                System.out.println("CustomerServlet Search - Query: '" + searchQuery + "', Gender: '" + genderFilter + "'");

                List<Customer> customerList = searchCustomers(searchQuery, genderFilter);

                // Debug output
                System.out.println("CustomerServlet Search - Results: " + (customerList != null ? customerList.size() : "null"));

                // Check if this is an AJAX request expecting JSON
                String acceptHeader = request.getHeader("Accept");
                boolean isAjaxRequest = acceptHeader != null && acceptHeader.contains("application/json");
                
                if (isAjaxRequest) {
                    // Return JSON response for AJAX requests
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");
                    
                    StringBuilder json = new StringBuilder();
                    json.append("{\"customers\":[");
                    
                    if (customerList != null && !customerList.isEmpty()) {
                        for (int i = 0; i < customerList.size(); i++) {
                            Customer customer = customerList.get(i);
                            if (i > 0) json.append(",");
                            
                            json.append("{")
                                .append("\"id\":").append(customer.getId()).append(",")
                                .append("\"name\":\"").append(escapeJson(customer.getName())).append("\",")
                                .append("\"email\":\"").append(escapeJson(customer.getEmail())).append("\",")
                                .append("\"phoneNumber\":\"").append(escapeJson(customer.getPhone())).append("\",")
                                .append("\"appointmentCount\":").append(getCustomerAppointmentCount(customer.getId()))
                                .append("}");
                        }
                    }
                    
                    json.append("]}");
                    
                    response.getWriter().write(json.toString());
                    System.out.println("CustomerServlet: Returning JSON response with " + (customerList != null ? customerList.size() : 0) + " customers");
                } else {
                    // Regular HTML response for form submissions
                    request.setAttribute("customerList", customerList);
                    request.getRequestDispatcher("/counter_staff/manage_customer.jsp").forward(request, response);
                }
            }
        } catch (NumberFormatException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=system_error");
        }

    }

    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Customer customer = new Customer();
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Staff still in session: " + request.getSession().getAttribute("staff"));

        if (!populateCustomerFromRequest(request, customer, null)) {
            preserveFormData(request);
            request.setAttribute("customer", customer);
            request.getRequestDispatcher("/counter_staff/register_customer.jsp").forward(request, response);
            return;
        }
        customerFacade.create(customer);
        request.setAttribute("success", "Customer registered successfully.");
        request.getRequestDispatcher("counter_staff/register_customer.jsp").forward(request, response);
    }

    private void handleUpdate(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Customer customer = customerFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Staff still in session: " + request.getSession().getAttribute("customer"));

        if (customer == null) {
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&error=customer_not_found");
            return;
        }

        if (!populateCustomerFromRequest(request, customer, customer.getEmail())) {
            request.setAttribute("customer", customer);
            response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=edit&id=" + customer.getId() + "&error=input_invalid");
            return;
        }

        customerFacade.edit(customer);
        request.setAttribute("success", "Customer updated successfully.");
        request.setAttribute("customer", customer);
        response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&success=customer_updated");
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Customer customer = customerFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("staff"));

        if (customer != null) {
            customerFacade.remove(customer);
        }
        response.sendRedirect(request.getContextPath() + "/CustomerServlet?action=viewAll&success=staff_deleted");
    }

    private boolean populateCustomerFromRequest(HttpServletRequest request, Customer customer, String existingEmail) throws IOException, ServletException {
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

        if (!email.equals(existingEmail) && customerFacade.searchEmail(email) != null) {
            request.setAttribute("error", "Email address is already registered.");
            return false;
        }

        try {
            customer.setName(name);
            customer.setEmail(email);
            customer.setPassword(password);
            customer.setPhone(phone);
            customer.setGender(gender);
            customer.setDob(Date.valueOf(dobStr));
            customer.setIc(nric);
            customer.setAddress(address);

        } catch (Exception e) {
            request.setAttribute("error", "Invalid input format.");
            return false;
        }

        // Handle profile picture
        Part file = request.getPart("profilePic");
        try {
            if (file != null && file.getSize() > 0) {
                String uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                customer.setProfilePic(uploadedFileName);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
            return false;
        }

        return true;
    }

    private void preserveFormData(HttpServletRequest request) throws IOException, ServletException {
        Customer customer = new Customer();
        customer.setName(readFormField(request.getPart("name")));
        customer.setEmail(readFormField(request.getPart("email")));
        customer.setPassword(readFormField(request.getPart("password")));
        customer.setPhone(readFormField(request.getPart("phone")));
        customer.setGender(readFormField(request.getPart("gender")));
        customer.setIc(readFormField(request.getPart("nric")));
        customer.setAddress(readFormField(request.getPart("address")));

        String dobStr = readFormField(request.getPart("dob"));
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                customer.setDob(Date.valueOf(dobStr));
            } catch (Exception ignored) {
            }
        }

        request.setAttribute("customer", customer);
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
    private List<Customer> searchCustomers(String searchQuery, String genderFilter) {
        List<Customer> allCustomers = customerFacade.findAll();
        if (allCustomers == null) {
            System.out.println("CustomerServlet searchCustomers - No customers found in database");
            return null;
        }

        System.out.println("CustomerServlet searchCustomers - Total customers: " + allCustomers.size());
        System.out.println("CustomerServlet searchCustomers - Search query: '" + searchQuery + "'");
        System.out.println("CustomerServlet searchCustomers - Gender filter: '" + genderFilter + "'");

        return allCustomers.stream()
                .filter(customer -> {
                    // Check search query match
                    boolean matchesSearch = true;
                    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                        String query = searchQuery.toLowerCase().trim();
                        String customerName = customer.getName() != null ? customer.getName().toLowerCase() : "";
                        String customerEmail = customer.getEmail() != null ? customer.getEmail().toLowerCase() : "";
                        String customerPhone = customer.getPhone() != null ? customer.getPhone().toLowerCase() : "";
                        String customerId = String.valueOf(customer.getId());
                        
                        matchesSearch = customerName.contains(query) || 
                                       customerEmail.contains(query) || 
                                       customerPhone.contains(query) ||
                                       customerId.equals(query);
                        
                        // Debug individual customer matching
                        System.out.println("Customer " + customer.getId() + " (" + customer.getName() + ", " + customer.getEmail() + ", " + customer.getPhone() + ") - Matches search: " + matchesSearch);
                    }

                    // Check gender filter match
                    boolean matchesGender = true;
                    if (genderFilter != null && !"all".equals(genderFilter)) {
                        String customerGender = customer.getGender();
                        matchesGender = genderFilter.equals(customerGender);
                        
                        // Debug gender matching
                        System.out.println("Customer " + customer.getId() + " - Gender: '" + customerGender + "', Filter: '" + genderFilter + "', Matches: " + matchesGender);
                    }

                    boolean finalMatch = matchesSearch && matchesGender;
                    if (finalMatch) {
                        System.out.println("Customer " + customer.getId() + " (" + customer.getName() + ") - INCLUDED in results");
                    }
                    
                    return finalMatch;
                })
                .sorted((m1, m2) -> Integer.compare(m1.getId(), m2.getId())) // Sort by ID for consistency
                .collect(Collectors.toList());
    }

    private boolean isStaffLoggedIn(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("staff") == null) {
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

    // Helper method to escape JSON strings
    private String escapeJson(String str) {
        if (str == null) return "";
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
                  .replace("\t", "\\t");
    }

    // Helper method to get customer appointment count (placeholder - you may want to implement this properly)
    private int getCustomerAppointmentCount(int customerId) {
        // For now, return 0. You can implement this later if you have an AppointmentFacade
        // that can query appointments by customer ID
        return 0;
    }

    @Override
    public String getServletInfo() {
        return "CustomerServlet - Handles CRUD operations for customers";
    }
}
