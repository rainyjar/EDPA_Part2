import java.io.IOException;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.ManagerFacade;
import java.sql.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.List;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.Part;
import model.Manager;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/ManagerServlet"})
@MultipartConfig

public class ManagerServlet extends HttpServlet {

    @EJB
    private ManagerFacade managerFacade;

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
     * methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
//    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
//            throws ServletException, IOException {
//        response.setContentType("text/html;charset=UTF-8");
//        try (PrintWriter out = response.getWriter()) {
//            /* TODO output your page here. You may use following sample code. */
//            out.println("<!DOCTYPE html>");
//            out.println("<html>");
//            out.println("<head>");
//            out.println("<title>Servlet ManagerServlet</title>");            
//            out.println("</head>");
//            out.println("<body>");
//            out.println("<h1>Servlet ManagerServlet at " + request.getContextPath() + "</h1>");
//            out.println("</body>");
//            out.println("</html>");
//        }
//    }
//    register new manager (not yet validate)
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html");
        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Manager manager = managerFacade.find(id);
            if (manager != null) {
                managerFacade.remove(manager);
            }
            response.sendRedirect("ManagerServlet");
        } else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Manager manager = managerFacade.find(id);

            if (manager != null) {
                manager.setName(request.getParameter("name"));
                manager.setEmail(request.getParameter("email"));
                manager.setPassword(request.getParameter("password"));
                manager.setPhone(request.getParameter("phone"));
                manager.setGender(request.getParameter("gender"));

                try {
                    String dobStr = request.getParameter("dob");
                    java.util.Date utilDate = new SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
                    java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
                    manager.setDob(sqlDate);
                } catch (ParseException e) {
                    e.printStackTrace();
                }

                Part file = request.getPart("profilePic");
                try {
                    String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                    if (uploadedFileName != null) {
                        manager.setProfilePic(uploadedFileName);
                    }
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    request.getRequestDispatcher("/manager/edit_manager.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Upload failed: " + e.getMessage());
                    request.getRequestDispatcher("/manager/edit_manager.jsp").forward(request, response);
                    return;
                }

                managerFacade.edit(manager);
            }
            response.sendRedirect("ManagerServlet");

        } else {
            // Registration block
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String phone = request.getParameter("phone");
            String gender = request.getParameter("gender");
            String dobStr = request.getParameter("dob");

            Date dob = null;
            if (dobStr != null && !dobStr.isEmpty()) {
                dob = Date.valueOf(dobStr);
            }

            String uploadedFileName = null;
            Part file = request.getPart("profilePic");

            try {
                uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
            } catch (IllegalArgumentException e) {
                request.setAttribute("error", e.getMessage());
                request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
                return;
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Upload failed: " + e.getMessage());
                request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
                return;
            }

            Manager m = new Manager();
            m.setName(name);
            m.setEmail(email);
            m.setPassword(password);
            m.setPhone(phone);
            m.setGender(gender);
            m.setDob(dob);
            m.setProfilePic(uploadedFileName);

            try {
                managerFacade.create(m);
                request.setAttribute("success", "Manager registered successfully.");
            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Failed to register manager: " + e.getMessage());
            }

            request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
        }
    }

//    retreive managers detail
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");

        if ("edit".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Manager manager = managerFacade.find(id);
            request.setAttribute("manager", manager);
            request.getRequestDispatcher("/manager/edit_manager.jsp").forward(request, response);
        } else {
            // Default: show list
            List<Manager> managerList = managerFacade.findAll();
            request.setAttribute("managerList", managerList);
            request.getRequestDispatcher("/manager/list_manager.jsp").forward(request, response);
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
