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
public class DoctorFacade extends AbstractFacade<Doctor> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public DoctorFacade() {
        super(Doctor.class);
    }

    public Doctor searchEmail(String email) {
        Query q = em.createNamedQuery("Doctor.searchEmail");
        q.setParameter("x", email);
        List<Doctor> result = q.getResultList();
        if (result.size() > 0) {
            return result.get(0);
        }
        return null;
    }
    
    /**
     * Update the rating for a specific doctor
     * @param doctorId The doctor ID
     * @param rating The new rating to set
     * @return true if update was successful, false otherwise
     */
    public boolean updateDoctorRating(int doctorId, double rating) {
        try {
            Query updateQuery = em.createQuery("UPDATE Doctor d SET d.rating = :rating WHERE d.id = :doctorId");
            updateQuery.setParameter("rating", rating);
            updateQuery.setParameter("doctorId", doctorId);
            int updatedRows = updateQuery.executeUpdate();
            return updatedRows > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Find doctors associated with a specific treatment
     * @param treatmentId The treatment ID
     * @return List of doctors who can perform this treatment
     */
    public List<Doctor> findDoctorsByTreatment(int treatmentId) {
        try {
            Query query = em.createQuery(
                "SELECT DISTINCT d FROM Doctor d " +
                "JOIN d.treatments t " +
                "WHERE t.id = :treatmentId"
            );
            query.setParameter("treatmentId", treatmentId);
            return query.getResultList();
        } catch (Exception e) {
            e.printStackTrace();
            return java.util.Collections.emptyList();
        }
    }
    
    /**
     * Find doctor by IC/NRIC
     * @param ic The IC/NRIC to search for
     * @return The doctor with the given IC/NRIC, or null if not found
     */
    public Doctor findByIc(String ic) {
        try {
            Query q = em.createQuery("SELECT d FROM Doctor d WHERE d.ic = :ic");
            q.setParameter("ic", ic);
            List<Doctor> results = q.getResultList();
            if (results.isEmpty()) {
                return null;
            }
            return results.get(0);
        } catch (Exception e) {
            System.err.println("Error finding doctor by IC " + ic + ": " + e.getMessage());
            return null;
        }
    }
}
