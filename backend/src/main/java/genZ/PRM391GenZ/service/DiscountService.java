package genZ.PRM391GenZ.service;


import genZ.PRM391GenZ.entity.DiscountCode;
import genZ.PRM391GenZ.repository.DiscountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;


@Service
@RequiredArgsConstructor
public class DiscountService {


    private final DiscountRepository repository;



    public List<DiscountCode> getAll(){

        return repository.findAll();

    }



    public DiscountCode create(
            DiscountCode discount){

        return repository.save(discount);

    }



    public DiscountCode update(
            Integer id,
            DiscountCode data){


        DiscountCode old =
                repository.findById(id)
                        .orElseThrow();


        old.setCode(data.getCode());
        old.setDescription(data.getDescription());
        old.setDiscountType(data.getDiscountType());
        old.setDiscountValue(data.getDiscountValue());
        old.setStartDate(data.getStartDate());
        old.setEndDate(data.getEndDate());
        old.setQuantity(data.getQuantity());
        old.setStatus(data.getStatus());


        return repository.save(old);

    }



    public void delete(Integer id){

        repository.deleteById(id);

    }


}