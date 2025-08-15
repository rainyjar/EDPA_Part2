/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

/**
 *
 * @author chris
 */
@Stateless
public class CounterStaffFacade extends AbstractFacade<CounterStaff> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public CounterStaffFacade() {
        super(CounterStaff.class);
    }

    public CounterStaff searchEmail(String email) {
        Query q = em.createNamedQuery("CounterStaff.searchEmail");
        q.setParameter("x", email);
        List<CounterStaff> result = q.getResultList();
        if (result.size() > 0) {
            return result.get(0);
        }
        return null;
    }
    
    /**
     * Update the rating for a specific counter staff
     * @param staffId The counter staff ID
     * @param rating The new rating to set
     * @return true if update was successful, false otherwise
     */
    public boolean updateCounterStaffRating(int staffId, double rating) {
        try {
            Query updateQuery = em.createQuery("UPDATE CounterStaff cs SET cs.rating = :rating WHERE cs.id = :staffId");
            updateQuery.setParameter("rating", rating);
            updateQuery.setParameter("staffId", staffId);
            int updatedRows = updateQuery.executeUpdate();
            return updatedRows > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Find counter staff by IC/NRIC
     * @param ic The IC/NRIC to search for
     * @return The counter staff with the given IC/NRIC, or null if not found
     */
    public CounterStaff findByIc(String ic) {
        try {
            Query q = em.createQuery("SELECT cs FROM CounterStaff cs WHERE cs.ic = :ic");
            q.setParameter("ic", ic);
            List<CounterStaff> results = q.getResultList();
            if (results.isEmpty()) {
                return null;
            }
            return results.get(0);
        } catch (Exception e) {
            System.err.println("Error finding counter staff by IC " + ic + ": " + e.getMessage());
            return null;
        }
    }

}
