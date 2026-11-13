import {z} from 'zod';

export const restaurantInputSchema=z.object({
  name:z.string().trim().min(2).max(120),
  slug:z.string().trim().toLowerCase()
    .min(3).max(50)
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/,'Use lowercase letters, numbers and internal hyphens'),
  branchName:z.string().trim().min(2).max(120)
});
export type RestaurantInput=z.infer<typeof restaurantInputSchema>;
export function validateRestaurantInput(value:unknown):RestaurantInput{
  return restaurantInputSchema.parse(value);
}
