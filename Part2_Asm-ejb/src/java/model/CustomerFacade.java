package model;

import java.util.ArrayList;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

@Stateless
public class CustomerFacade extends AbstractFacade<Customer> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public CustomerFacade() {
        super(Customer.class);
    }

    public Customer searchEmail(String email) {
        Query q = em.createNamedQuery("Customer.searchEmail");
        q.setParameter("x", email);
        List<Customer> result = q.getResultList();
        if (result.size() > 0) {
            return result.get(0);
        }
        return null;
    }

    /**
     * Find customer by ID - required for counter staff operations
     */
    public Customer findById(int customerId) {
        try {
            return em.find(Customer.class, customerId);
        } catch (Exception e) {
            System.err.println("Error finding customer by ID " + customerId + ": " + e.getMessage());
            return null;
        }
    }

    /**
     * Search customers by name (partial match) - useful for counter staff
     */
    public List<Customer> searchByName(String name) {
        try {
            Query q = em.createQuery("SELECT c FROM Customer c WHERE LOWER(c.name) LIKE LOWER(:name) ORDER BY c.name");
            q.setParameter("name", "%" + name + "%");
            return q.getResultList();
        } catch (Exception e) {
            System.err.println("Error searching customers by name: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Search customers by phone number - useful for counter staff
     */
    public Customer searchByPhoneNumber(String phoneNumber) {
        try {
            Query q = em.createQuery("SELECT c FROM Customer c WHERE c.phone = :phone");
            q.setParameter("phone", phoneNumber);
            List<Customer> result = q.getResultList();
            if (result.size() > 0) {
                return result.get(0);
            }
        } catch (Exception e) {
            System.err.println("Error searching customer by phone: " + e.getMessage());
        }
        return null;
    }

}
