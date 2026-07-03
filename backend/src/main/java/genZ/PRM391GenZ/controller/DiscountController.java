package genZ.PRM391GenZ.controller;


import genZ.PRM391GenZ.entity.DiscountCode;
import genZ.PRM391GenZ.service.DiscountService;

import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.*;

import java.util.List;



@RestController
@RequestMapping("/api/discount")
@RequiredArgsConstructor
@CrossOrigin("*")
public class DiscountController {



    private final DiscountService service;



    @GetMapping
    public List<DiscountCode> getAll(){

        return service.getAll();

    }



    @PostMapping
    public DiscountCode create(
            @RequestBody DiscountCode discount){

        return service.create(discount);

    }




    @PutMapping("/{id}")
    public DiscountCode update(
            @PathVariable Integer id,
            @RequestBody DiscountCode discount){

        return service.update(id,discount);

    }




    @DeleteMapping("/{id}")
    public String delete(
            @PathVariable Integer id){

        service.delete(id);

        return "Delete success";

    }


}